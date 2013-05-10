This is the command line interface main entry point, set up the required
modules and the command sub modules here.

    docopt = require 'docopt'
    path = require 'path'
    fs = require 'fs'
    _ = require 'lodash'
    yaml = require 'js-yaml'
    wrench = require 'wrench'
    require('colors').setTheme
        info: 'green'
        error: 'red'
        warn: 'yellow'
        debug: 'blue'

Color!

    console.error_save = console.error
    console.error = (args...)->
        colorized = _.map args, ((x) -> x.error)
        console.error_save.apply null, colorized


Making a little patch to require in order to get options, probably should
fork docopt and add this feature.

    require.extensions['.docopt'] = (module, filename) ->
        doc = fs.readFileSync filename, 'utf8'
        module.exports =
            options: docopt.docopt doc, version: require('../package.json').version
            help: doc

The actual command line processing.

    cli = require './cli.docopt'

Full on help

    if cli.options['--help']
        console.log cli.help

Root directory needs to be in the environment

    cli.options.root = path.resolve cli.options['--directory'] or process.env['NOTIFY_ROOT'] or process.cwd()
    cli.options.username = cli.options['<username>'] or process.env['USER']

Debugging information helps sometimes

    if cli.options['--debug']
        console.log cli.options

User directories need to exist

    ensure_user = (options) ->
        if options.username
            user = path.join options.root, options.username
            options.new_dir = new_dir = path.join user, 'new'
            options.tmp_dir = tmp_dir = path.join user, 'tmp'
            options.cur_dir = cur_dir = path.join user, 'cur'
            for dir in [user, new_dir, tmp_dir, cur_dir]
                if not fs.existsSync dir
                    wrench.mkdirSyncRecursive dir

The sub-commands start here

Init, make the root directory

    init = (options) ->
        if not fs.existsSync options.root
            wrench.mkdirSyncRecursive options.root
        process.exit 0

Sending, this is the heart of the matter

    send = (options) ->
        data =
            tags: _.map (options['--tags'] or '').split(','), (x) -> x.trim()
            message: options['--message'] or ''
            link: options['--link'] or ''
        if options['--context'] and fs.existsSync(options['--context'])
            data.context = yaml.safeLoad(fs.readFileSync(options['--context'], 'utf8'))
        file_name = "#{Date.now()}.#{process.pid}.yaml"
        fs.writeFileSync path.join(options.tmp_dir, file_name), yaml.safeDump(data)
        fs.renameSync path.join(options.tmp_dir, file_name), path.join(options.new_dir, file_name)

Peeking, almost like receiving, just without the move to the delivered folder

    peek = (options) ->
        send_files = []
        for file in fs.readdirSync options.new_dir
            if file.slice(-4) is 'yaml'
                full_name = path.join options.new_dir, file
                send_files.push
                    when: Number(file.split('.')[0])
                    name: file
                    data: yaml.safeLoad fs.readFileSync(full_name, 'utf8')
        #ok, this looks a bit odd, but it is descending sort, really, no kidding
        send_files = _.sortBy send_files, (x) -> 9007199254740992 - x.when
        process.stdout.write yaml.safeDump _.map(send_files, (x) -> _.pick(x, 'data', 'when'))
        send_files

Receiving, which is all the files new just now, in order, and then moving them
aside to note that they are delivered

    receive = (options) ->
        send_files = peek options
        for file in _.map(send_files, (x) -> x.name)
            fs.renameSync path.join(options.new_dir, file), path.join(options.cur_dir, file)

Clearing, which is all about making things go away

    clear = (options) ->
        count = 0
        for file in fs.readdirSync options.cur_dir
            fs.unlinkSync path.join(options.cur_dir, file)
            count++
        console.log "#{count} files cleared".info

Info about the user

    about = (options) ->
        about =
            username: options.username
            directory: path.join options.root, options.username
        console.log JSON.stringify(about)

Go!

    cli.options.init and init cli.options
    ensure_user cli.options
    cli.options.send and send cli.options
    cli.options.peek and peek cli.options
    cli.options.receive and receive cli.options
    cli.options.clear and clear cli.options
    cli.options.about and about cli.options

