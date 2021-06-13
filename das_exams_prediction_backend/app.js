var createError = require('http-errors');
var express = require('express');
var path = require('path');
var cookieParser = require('cookie-parser');
var logger = require('morgan');
var cors = require('cors');
var session = require('express-session');

var indexRouter = require('./routes/index');
var usersRouter = require('./routes/users');
var dashbaord = require('./routes/dashboard');
var dashboardapis = require('./routes/dashboardapis');
var helpers = require('./routes/includes/helpers');

var bodyParser = require("body-parser");
var exphbs  = require('express-handlebars');
var fileUpload = require('express-fileupload');

var app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true, limit: "50mb" }));
app.use(fileUpload({
  useTempFiles: true,
  tempFileDir : '/tmp/',
  limits: { fileSize: 50 * 1024 * 1024 },
}));
// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'hbs');
app.set('trust proxy', 1) // trust first proxy

app.engine('hbs', exphbs({
  layoutsDir:`${__dirname}/views/layouts`,
  partialsDir:`${__dirname}/views/partials`,
  extname:"hbs",
  helpers: helpers
}));

app.use(cors({
  origin: '*',
  credentials: true,
  exposedHeaders: ['set-cookie']
}));
app.use(session({
  secret: 'wow very secret',
  cookie: {
    maxAge: 600000000,
    secure: false
  },
  saveUninitialized: false,
  resave: true,
  unset: 'destroy'
}))
app.use(express.static('public'));
app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());

app.use('/api/', indexRouter);
app.use('/api/auth/users', usersRouter);
app.use('/dash/',dashbaord);
app.use('/dash/api/',dashboardapis);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error',{layout:false});
});

module.exports = app;
