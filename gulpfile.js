var gulp = require('gulp')
    , path = require("path")
    , less = require("gulp-less")
    , coffee = require("gulp-coffee")
    , gutil = require('gulp-util')
    , plumber = require('gulp-plumber')
    , concat = require('gulp-concat')
    , browserSync = require('browser-sync')
    , reload = browserSync.reload;

gulp.task('browser-sync', function () {
    browserSync({
        server: {
            baseDir: "./build"
        }
    });
});

gulp.task('less', function () {
    gulp.src('./src/less/**/*.less')
        .pipe(plumber(function (error) {
            gutil.log(gutil.colors.red(error.message));
            gutil.beep();
            this.emit('end');
        }))
        .pipe(less({}))
        .pipe(gulp.dest('./build/css'))
        .pipe(reload({stream: true}));
});


gulp.task('coffee', function () {
    gulp.src([
        './src/coffee/models.coffee',
        './src/coffee/views.coffee',
        './src/coffee/app.coffee'
    ])
        .pipe(concat('app.coffee'))
        .pipe(coffee())
        .pipe(gulp.dest('./build/js'))
        .pipe(reload({stream: true}));
});

gulp.task('html', function () {
    gulp.src('./src/*.html')
        .pipe(gulp.dest('./build'))
        .pipe(reload({stream: true}));
});

gulp.task('vendor', function () {
    gulp.src([
        'bower_components/bootstrap/dist/css/bootstrap.min.css',
        //'bower_components/bootstrap/dist/css/bootstrap-theme.min.css',
        'bower_components/fontawesome/css/font-awesome.min.css'
    ])
        .pipe(concat('vendor.css'))
        .pipe(gulp.dest('./build/css'));

    gulp.src([
        'bower_components/jquery/dist/jquery.min.js',
        'bower_components/eventEmitter/EventEmitter.min.js',
        'bower_components/bootstrap/dist/js/bootstrap.min.js',
        'bower_components/react/react.js'
    ])
        .pipe(concat('vendor.js'))
        .pipe(gulp.dest('./build/js'));

    gulp.src([
        'bower_components/fontawesome/fonts/*.*'
    ])
        .pipe(gulp.dest('./build/fonts'));
});

gulp.task('all:watch', function () {
    gulp.watch(['./src/coffee/**/*.coffee'], ['coffee']);
    gulp.watch(['./src/less/**/*.less'], ['less']);
    gulp.watch(['./src/*.html'], ['html']);
});

gulp.task('default', ['vendor', 'less', 'coffee', 'html', 'browser-sync', 'all:watch']);