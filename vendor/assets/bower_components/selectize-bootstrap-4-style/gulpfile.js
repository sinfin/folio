var gulp = require('gulp');
var sass = require('gulp-sass');

// Compile stylus to csss
gulp.task('sass', function(){
	return gulp.src(['./src/bootstrap/bootstrap.scss', './src/selectize/selectize.bootstrap4.scss'])
		.pipe(sass().on('error', sass.logError))
		.pipe(gulp.dest('./dist/css'));
});

// Declare the tasks
gulp.task('default', [ 'sass'], function() {
	gulp.watch(['src/**/*.scss'], [ 'sass']);
});