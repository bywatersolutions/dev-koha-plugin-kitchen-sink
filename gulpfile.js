const { dest, series, src } = require('gulp');
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

const fs = require('fs');
const dateTime = require('node-datetime');
const Vinyl = require('vinyl');
const path = require('path');
const stream = require('stream');

const dt = dateTime.create();
const today = dt.format('Y-m-d');

const package_json = JSON.parse(fs.readFileSync('./package.json'));
const release_filename = `${package_json.name}-v${package_json.version}.kpz`;

const pm_name = 'KitchenSink';
const pm_file = pm_name+'.pm';
const pm_file_path = path.join('Koha', 'Plugin', 'Com', 'ByWaterSolutions');
const pm_file_path_full = path.join(pm_file_path, pm_file);
const pm_file_path_dist = path.join('dist', pm_file_path);
const pm_file_path_full_dist = path.join(pm_file_path_dist, pm_file);
const pm_bundle_path = path.join(pm_file_path, pm_name);

/**
 *
 * Array of directories relative to pm_bundle_path where static files will be served
 *
 * If no static files need to be served, set static_relative_path = []
 *
 */
const static_relative_path = ['static_files', 'datepicker'];

var static_absolute_path = [];

if(static_relative_path.length) {
    static_absolute_path = static_relative_path.map(dir=>path.join(pm_bundle_path, dir)+'/**/*');
}

console.log(release_filename);
console.log(pm_file_path_full_dist);

function static( cb ) {
    if(static_absolute_path.length) {
        let spec_body = JSON.stringify({
            get: {
                'x-mojo-to': 'Static#get',
                tags: ['pluginStatic'],
                responses: {
                    200: {
                        description: 'File found',
                        schema: {
                            type: 'file'
                        }
                    },
                    404: {
                        description: 'File not found',
                        schema: {
                            type: 'object',
                            properties: {
                                error: {
                                    description: "An explanation for the error",
                                    type: "string"
                                }
                            }
                        }
                    },
                    400: {
                        description: 'Bad request',
                        schema: {
                            type: 'object',
                            properties: {
                                error: {
                                    description: "An explanation for the error",
                                    type: "string"
                                }
                            }
                        }
                    },
                    500: {
                        description: 'Internal server error',
                        schema: {
                            type: 'object',
                            properties: {
                                error: {
                                    description: "An explanation for the error",
                                    type: "string"
                                }
                            }
                        }
                    }
                }
            }
        }, null, 2);

        let bufArray = [];
        
        return src(static_absolute_path)
            .pipe(new stream.Transform({
                objectMode: true,
                transform: (file, unused, cb) => {
                    if(file.stat.isDirectory()) return cb();
                    let path_name = path.join('/', path.relative(pm_bundle_path, file.base), file.relative);
                    console.log('creating '+path_name);
                    let endpoint_spec = '"'+path_name+'": '+ spec_body;
                    bufArray.push(endpoint_spec);
                    cb();
                },
                flush: function(cb) {
                    let file = new Vinyl({
                        path: 'staticapi.json',
                        contents: Buffer.from('{\n'+bufArray.join(',\n')+'\n}')
                    });
                    this.push(file);
                    cb();
                }
            }))
            .pipe(dest(pm_bundle_path));
    }
    else {
        cb();
    }
};

async function build() {
  await execPromise('mkdir -p dist');
  await execPromise('cp -r Koha dist/.');
  await execPromise(`sed -i -e "s/1970-01-01/${today}/g" ${pm_file_path_full_dist}`);
  await execPromise(`cd dist && zip -r ../${release_filename} ./Koha`);
  await execPromise('rm -rf dist');
}

exports.static = static;
exports.build  = series( static, build );
