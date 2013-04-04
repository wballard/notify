This is the command line interface main entry point, set up the required
modules and the command sub modules here.

    docopt = require 'docopt'
    path = require 'path'
    fs = require 'fs'
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

 root directory needs to be in the environment

    cli.options.root = path.resolve cli.options['--directory'] or process.env['NOTIFY_ROOT'] or process.cwd()

Defaults, docopt isn't super smart about this part, so scrub some options.

    for name, value of cli.options
        if name.slice(0,2) is '--'
            cli.options[name.slice(2)] = value
        if name.slice(0,1) is '<' and name.slice(-1) is '>'
            cli.options[name.slice(1,-1)] = value

Debugging information helps sometimes

    if cli.options['--debug']
        console.log cli.options

The sub-commands start here

Init, make the root directory

    init = (options) ->
        if not fs.existsSync options.root
            console.log "Initializing #{options.root}".info
            fs.mkdirSync options.root

Go!

    cli.options.init and init cli.options

