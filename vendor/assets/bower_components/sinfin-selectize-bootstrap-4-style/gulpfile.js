'use strict';

var gulp = require('gulp');
var sass = require('gulp-sass');

// Compile sass to css
function sassCompile(cb){
	gulp.src(['./src/bootstrap/bootstrap.scss', './src/selectize/selectize.bootstrap4.scss'])
		.pipe(sass().on('error', sass.logError))
		.pipe(gulp.dest('./dist/css'));
	cb();	
};

gulp.watch(['src/**/*.scss'], gulp.series(sassCompile));
exports.default = gulp.series(sassCompile);