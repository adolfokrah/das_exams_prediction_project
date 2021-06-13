var express = require('express');
var router = express.Router();
var connect = require('./includes/connect');
var fs = require("fs");
var md5 = require('md5');
var moment = require('moment');

/* GET users listing. */
router.get('/', function(req, res, next) {
  res.send('respond with a resource');
});

router.post('/register', async (req,res)=>{
  //get user data from post request
  var data = req.body;
  data.password = md5(data.password);
  data.expiration = new Date();
  data.joined_date = new Date();
  data.scode = `${data.username[0]}${data.username[1]}`;
  var d  = moment(new Date()).format('DD YYYY M s');
  d = d.split(' ');
  d = d.join('');
  data.scode += d;
  data.scode = data.scode.toUpperCase();
  if(data.sponsor.trim().length < 1){
     data.sponsor = '-';
  }
  
  //check if user already exist
  var queryCheck = await connect.select('*').from('users').where({email: data.email});
  if(queryCheck.length > 0){
    res.status(201).send('User already exist');
    return;
  }
  //insert data to database
  var query = await connect.insert(data).into('users');
  data = await connect.select('*').from('users').where({email: data.email});
  data = data[0];
  res.status(200).send(data);
})

router.post('/login',async(req,res)=>{
  var data = req.body;
  if(data.password == 'social'){
    delete data.password;
  }else{
    data.password = md5(data.password);
  }
  
  //check if user exist
  var checkUser = await connect.select('*').from('users').where(data);
  if(checkUser.length < 1){
    res.status(201).send('Sorry, you provided the worng credentails');
    return;
  }

  console.log(checkUser[0]);
  
  res.status(200).send(checkUser[0]);
})

router.post('/updateprofile',async(req,res)=>{
  var data = req.body;
  var img = req.files;
  if(img){
    var path = 'public/uploads/images/'+img.photo.name;
    await img.photo.mv(path);
    data.photo = req.files.photo.name;
    delete data.photoName;
  }else{
    delete data.photoName;
    delete data.photo;
  }

  
  //update user profile
  if(data.password == ''){
    delete data.password;
  }else{
    data.password = md5(data.password);
  }

  var queryCheck = await connect.select('*').from('users').where('email','=',data.email).andWhere('user_id','<>',data.user_id);
  if(queryCheck.length > 0){
    res.status(201).send('error');
    return;
  }

  var details = await connect.select('*').from('users').where('user_id','=',data.user_id);
  if(new Date(details[0].expiration) <= new Date()){
    data.expired = "true";
  }
  
  var queryCheck = await connect('users').update(data).where({user_id: data.user_id});
  var user_details = await connect.select('*').from('users').where('user_id','=',data.user_id);
  res.status(200).send(user_details[0]);
 
})

module.exports = router;
