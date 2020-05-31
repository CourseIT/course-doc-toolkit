#! /usr/bin/env node

const { readFileSync, writeFileSync } = require('fs')
const { resolve, basename, dirname } = require('path')
const nunjucks = require('nunjucks')
const chokidar = require('chokidar')
const glob = require('glob')
const mkdirp = require('mkdirp')
const chalk = require('chalk').default

const { argv } = require('yargs')
	.usage('Usage: nunjucks <file|glob> [context] [options]')
	.example('nunjucks foo.tpl data.json', 'Compile foo.tpl to foo.html')
	.example('nunjucks *.tpl -w -p src -o dist', 'Watch .tpl files in ./src, compile them to ./dist')
	.demandCommand(1, 'You must provide at least a file/glob path')
	.epilogue('For more information on Nunjucks: https://mozilla.github.io/nunjucks/')
	.help()
	.alias('help', 'h')
	.locale('en')
	.version(false)
	.option('path', {
		alias: 'p',
		string: true,
		requiresArg: true,
		nargs: 1,
		describe: 'Path where templates live',
	})
	.option('out', {
		alias: 'o',
		string: true,
		requiresArg: true,
		nargs: 1,
		describe: 'Output folder',
	})
	.option('watch', {
		alias: 'w',
		boolean: true,
		describe: 'Watch files change, except files starting by "_"',
	})
	.option('extension', {
		alias: 'e',
		string: true,
		requiresArg: true,
		default: 'html',
		describe: 'Extension of the rendered files',
	})
	.option('options', {
		alias: 'O',
		string: true,
		requiresArg: true,
		nargs: 1,
		describe: 'Nunjucks options file',
	})

const inputDir = resolve(process.cwd(), argv.path) || ''
const outputDir = argv.out || ''

const context = argv._[1] ? JSON.parse(readFileSync(argv._[1], 'utf8')) : {}
// Expose environment variables to render context
context.env = process.env

/** @type {nunjucks.ConfigureOptions} */
const nunjucksOptions = argv.options
	? JSON.parse(readFileSync(argv.options, 'utf8'))
	: { trimBlocks: true, lstripBlocks: true, noCache: true }

const nunjucksEnv = nunjucks.configure(inputDir, nunjucksOptions)

nunjucksEnv.addFilter('md2asciidoc', function(a) {
  a = a.replace(/C\+\+/g, '{cpp}' );
  a = a.replace(/С\+\+/g, '{cpp}' );  
  a = a.replace(/\&nbsp\;/g, '\xA0' );
  a = a.replace(/\&amp\;/g, '&' );
  a = a.replace(/\&gt\;/g, '>' );
  a = a.replace(/\&lt\;/g, '<' );
  a = a.replace(/[ ]+[\n]/g, '\n' );
  a = a.replace(/<a[ ]*[^\n]*href="([^\n]*)"[^\n]*target[^\n]*>([^\n]*)<\/a>/g, 'link:\$1[\$2]' );
  a = a.replace(/([^\n^>])[\n]([^\n^>])/g, '\$1tyutyutyu\$2' );
  a = a.replace(/^[>][\ ]*([a-zA-Zа-яА-Я0-9\ё\_\:\xA0\ \(\)\*\.\'\`\$\&\%\#\@\[\]\{\}\|\;\-\+\—\–\,\«\»\?\/\\\!]*)/gm, '\n====\n\$1\n====\n' );
  a = a.replace(/([*][^*]+)tyutyutyu([^*]+[*])/gm, '\$1*tyutyutyu*\$2' );
  a = a.replace(/tyutyutyu/g, '\n\n' );
  a = a.replace(/====[\n]*====/g, '' );
//  a = a.replace(/(\n[^>][^\n]*)\n>/g, '\1\n====\n' );

//  a = a.replace(/^[>]/gm, 'TIP: ' );
  return a;
});

nunjucksEnv.addFilter('ansiToGerman', function(dateValue) {
      if ((dateValue == null) || (dateValue === "")) {
                return "—"
            }
      let day = dateValue.split("-")[2];
      if (! day) {
              return "—"
            }
      if (day.includes('T') && day.includes('Z')) {
                day = day.slice(0, 2);
            }
      let month = dateValue.split("-")[1];
      let year = dateValue.split("-")[0];
      return day + "." + month + "." + year 
});

nunjucksEnv.addFilter('from_translit', function(a) {
    a = a.replace(/target_transition/g , 'целевой-переход-состояния' );
    a = a.replace(/display_name/g , 'отображаемое-имя' );
    a = a.replace(/state/g , 'статус' );
    a = a.replace(/shh/g , 'щ' );
    a = a.replace(/yo/g  , 'ё' );
    a = a.replace(/zh/g  , 'ж' );
    a = a.replace(/cz/g  , 'ц' );
    a = a.replace(/ch/g  , 'ч' );
    a = a.replace(/sh/g  , 'ш' );
    a = a.replace(/yh/g  , 'ы' );
    a = a.replace(/qq/g  , 'ъ' );
    a = a.replace(/eh/g  , 'э' );
    a = a.replace(/yu/g  , 'ю' );
    a = a.replace(/ya/g  , 'я' );
    a = a.replace(/a/g   , 'а' );
    a = a.replace(/e/g   , 'е' );
    a = a.replace(/i/g   , 'и' );
    a = a.replace(/o/g   , 'о' );
    a = a.replace(/u/g   , 'у' );
    a = a.replace(/j/g   , 'й' );
    a = a.replace(/q/g   , 'ь' );
    a = a.replace(/b/g   , 'б' );
    a = a.replace(/v/g   , 'в' );
    a = a.replace(/g/g   , 'г' );
    a = a.replace(/d/g   , 'д' );
    a = a.replace(/z/g   , 'з' );
    a = a.replace(/k/g   , 'к' );
    a = a.replace(/l/g   , 'л' );
    a = a.replace(/m/g   , 'м' );
    a = a.replace(/n/g   , 'н' );
    a = a.replace(/p/g   , 'п' );
    a = a.replace(/r/g   , 'р' );
    a = a.replace(/s/g   , 'с' );
    a = a.replace(/t/g   , 'т' );
    a = a.replace(/f/g   , 'ф' );
    a = a.replace(/x/g   , 'х' );
    a = a.replace(/_/g   , '-' );
    return a;
});

const render = (/** @type {string[]} */ files) => {
	for (const file of files) {
		// No performance benefits in async rendering
		// https://mozilla.github.io/nunjucks/api.html#asynchronous-support
		const res = nunjucksEnv.render(file, context)

		let outputFile = file.replace(/\.\w+$/, `.${argv.extension}`)

		if (outputDir) {
			outputFile = resolve(outputDir, outputFile)
			mkdirp.sync(dirname(outputFile))
		}

		console.log(chalk.blue('Rendering: ' + file))
		writeFileSync(outputFile, res)
	}
}

/** @type {glob.IOptions} */
const globOptions = { strict: true, cwd: inputDir, ignore: '**/_*.*', nonull: true }

// Render the files given a glob pattern (except the ones starting with "_")
glob(argv._[0], globOptions, (err, files) => {
	if (err) return console.error(chalk.red(err))
	render(files)
})

// Watcher
if (argv.watch) {
	const layouts = []
	const templates = []

	/** @type {chokidar.WatchOptions} */
	const watchOptions = { persistent: true, cwd: inputDir }
	const watcher = chokidar.watch(argv._[0], watchOptions)

	watcher.on('ready', () => console.log(chalk.gray('Watching templates...')))

	// Sort files to not render partials/layouts
	watcher.on('add', (file) => {
		if (basename(file).indexOf('_') === 0) layouts.push(file)
		else templates.push(file)
	})

	// if the file is a layout/partial, render all other files instead
	watcher.on('change', (file) => {
		if (layouts.indexOf(file) > -1) render(templates)
		else render([file])
	})
}
