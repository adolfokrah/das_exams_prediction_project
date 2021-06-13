var express = require('express');
var router = express.Router();
var connect = require('./includes/connect');
var base64 = require('base-64');
const Flutterwave = require('flutterwave-node-v3');
var moment = require('moment');
var fs = require('fs');

/* GET home page. */

router.get('/get_upgrade_amount/:id', async(req, res)=>{
  var results = await connect.select('*').from('upgrade_amount');
  var query2 = await connect.select('*').from('users').where({user_id: req.params.id});
  var sponsor = await connect.select('*').from('users').where({scode: query2[0].sponsor});
  
  var data = results[0];
  data.userData = query2[0];
  if(sponsor.length > 0){
     data.monthlyD = data['monthly'] - (10/100 * data['monthly']);
     data.yearlyD = data['yearly'] - (10/100 * data['yearly']);
  }else{
    data.monthlyD = 0;
    data.yearlyD = 0;
  }
  
  res.send(data);
});

router.get('/upgrade/:token',async(req,res)=>{
    var token = base64.decode(req.params.token);
    var token = token.split(':');
    //get upgrade cost
    var query = await connect.select('*').from('upgrade_amount');
    var results = query[0];
    var amount = 0;
    if(token[0] == 'monthly'){
      amount = results.monthly;
    }else{
      amount = results.yearly;
    }
    var query2 = await connect.select('*').from('users').where({user_id: token[1]});
    if(query2.length < 1){
      res.status(404).send();
      return;
    }
    
    var data = query2[0];

    data['amount'] = amount;
    data['duration'] = token[0];
    var sponsor = await connect.select('*').from('users').where({scode: data.sponsor});

    if(sponsor.length > 0){
      data['amount'] = data['amount'] - (10/100 * amount);
    }

    
    res.render('upgrade',{layout: false, data: data});
});

router.get('/verifyT/:status/:tx_ref/:transaction_id/:user_id/:duration/',async(req,res)=>{

  const flw = new Flutterwave("FLWPUBK_TEST-6d8586b2aa1c61a02f1853acf364e3f8-X", "FLWSECK_TEST-8b1db21eab1f4daa4c4761286dd505d0-X");
  try {
      const payload = {"id": req.params.transaction_id} //This is the transaction unique identifier. It is returned in the initiate transaction call as data.id}
      const response = await flw.Transaction.verify(payload);

      if(response.data.status == 'successful'){
        var date = '';
        if(req.params.duration == 'monthly'){
           date = moment().add(1, 'month').add(1,'day').format('YYYY-M-D');
        }else{
           date = moment().add(1, 'year').add(1,'day').format('YYYY-M-D');
        }
        

        await connect('users').update({expiration: date,expired:'false'}).where({user_id: req.params.user_id});

        var query2 = await connect.select('*').from('users').where({user_id: req.params.user_id});
        if(query2[0].sponsor !='-'){
          var  date = moment().add(2, 'weeks').add(1,'day').format('YYYY-M-D');
          await connect('users').update({expiration: date,expired: 'false'}).where({scode: query2[0].sponsor});
          await connect('users').update({sponsor: "-"}).where({user_id: query2[0].user_id}).andWhere('expiration','<=',moment(new Date()).format('YYYY-MM-DD'));
        }

        res.status(200).send('success');
      }else{
        res.status(200).send('error');
      }
  } catch (error) {
      console.log(error)
      res.status(200).send('error');
  }
 
});

router.get('/getYears/:exam_type',async(req,res)=>{
  var exam_type = req.params.exam_type;
  var fetch = await connect.select("*").from('quetions').leftJoin('exam_type','quetions.exam_type','exam_type.e_id').where('exam_type.type','=',exam_type).orderBy('quetions.year','desc').groupBy('quetions.year');


  var array = fetch;

  res.status(200).send(array);
})

router.get('/getSubjects/:year/:exam_type/:user_id',async(req,res)=>{
  var year = req.params.year;
  var exam_type_id = req.params.exam_type;

  var Dyear = await connect.select('*').from('current_year').where('year','=',year);
  var user = await connect.select('*').from('users').where({user_id: req.params.user_id});

 
  if(Dyear.length > 0){
    if(year == Dyear[0].year && user[0].expiration <= new Date()){
      res.status(201).send('subscribe');
      return;
    }
  }

  var fetch = await connect.select("*").from('quetions').leftJoin('subject','quetions.subject','subject.sub_id').where('quetions.year','=',year).andWhere('quetions.exam_type','=',exam_type_id).groupBy('quetions.subject');
  res.status(200).send(fetch);
})

router.get('/getTopics/:subject/:exam_type/:year',async(req,res)=>{
  var subject = req.params.subject;
  var year = req.params.year;
  var exam_type_id = req.params.exam_type;
  var table = await getTable(req.params.year);
  var fetch = await connect.select("*").from("quetions").leftJoin('subject','quetions.subject','subject.sub_id').leftJoin('topic','quetions.topic','topic.t_id').where('subject.subject','=',subject).andWhere('quetions.exam_type','=',exam_type_id).andWhere('quetions.year','=',year).groupBy('quetions.topic');

  var array = [];

  console.log(fetch);

  for(var index in fetch){
    var questionsSections = await connect.select('type').from('quetions').where('topic','=',fetch[index].t_id).andWhere('year','=',req.params.year).andWhere('exam_type','=',exam_type_id).groupBy('type');
    fetch[index].sections = questionsSections;
    array.push(fetch[index]);
  }


  var data ={};
  data.topics = array;
  data.title = table == 'quetions' ? req.params.year+" "+subject+" past Topics and questions" : "Predicted topics and questions for "+req.params.year+" upcoming "+subject+" exams";
  

  res.status(200).send(data);
})

//get topic questions from the database
router.get('/fetch_questions/:section/:topic_id/:year/:exam_type',async(req,res)=>{
    var topic_id = req.params.topic_id;
    var section = req.params.section;
    var examType = req.params.exam_type;
    var table = await getTable(req.params.year);

    var questions = await connect.select('*').from('quetions').leftJoin('answers','quetions.q_id','answers.question_id').where('quetions.topic','=',topic_id).andWhere('quetions.type','=',section).andWhere('quetions.exam_type',examType).andWhere('quetions.year','=',req.params.year).orderBy('quetions.q_id','asc');

    if(questions.length > 0){
      await connect('quetions').update({views: connect.raw('?? +'+1,['views'])}).where({
        exam_type:questions[0].exam_type,
        subject: questions[0].subject
      });
    }
    var data ={};
    data.questions = questions;
    data.future = table;

    res.status(200).send(data);
})

router.get('/getSubmittedQuestions/:user_id/:start/:type',async(req,res)=>{
   var user_id = req.params.user_id;
   var submittedPendingQuestions;
   var answeredQuestions ;

   if(req.params.type == 'all' || req.params.type == 'pending'){
     submittedPendingQuestions =  await connect.select('*').from('submitted_questions').where('status','=','pending').andWhere('user_id','=',user_id).limit(10).offset(req.params.start).orderBy('sq_id','desc');
   }else{
    submittedPendingQuestions = [];
   }

   if(req.params.type == 'all' || req.params.type == 'answered'){
    answeredQuestions =  await connect.select('*').from('submitted_questions').leftJoin('f_answers','submitted_questions.sq_id','f_answers.question_id').where('submitted_questions.user_id','=',user_id).andWhere('submitted_questions.status','=','answered').groupBy('submitted_questions.sq_id').limit(5).offset(req.params.start).orderBy('sq_id','desc');
  }else{
    answeredQuestions =[];
  }

   var data = {
     'pendingQuestions': submittedPendingQuestions,
     'answeredQuestions': answeredQuestions
   };

   res.status(200).send(data);

})

router.get('/delete_question/:question_id',async(req,res)=>{
  var id = req.params.question_id;
  await connect('submitted_questions').update({'status':'deleted'}).where('sq_id','=',id);
  res.status(200).send('okay');
})

router.post('/submit_question',async(req,res)=>{
   var data  = req.body;
   //upload attached document if found
   if(req.files){
     if(req.files.doc){
      var document = req.files.doc;
      var uploadPath = 'public/uploads/docs/question_'+data.user_id+'_'+ document.name;
  
      await document.mv(uploadPath);
      data.file = 'question_'+data.user_id+'_'+ document.name;
     }
      //first upload question image if found
    if(req.files.photo){
      await req.files.photo.mv('public/uploads/images/question_'+data.user_id+'_'+req.files.photo.name);
      data.question_pic = 'https://dasexamprediction.biztrustgh.com/uploads/images/question_'+data.user_id+'_'+req.files.photo.name;
      
    }
   }

   data.date = new Date();

   delete data.photo;
   delete data.photoName;

   var query;
   if(data.edit == 'false'){
     delete data.edit;
     query = await connect.insert(data).into('submitted_questions');
   }else{
    delete data.edit;
    await connect('submitted_questions').update(data).where({sq_id: data.sq_id});
   }
   
   res.status(200).send('Okay');
})

router.get('/allTopics',async(req,res)=>{
   var topics = await connect.select('*').from('topic');
   res.status(200).send(topics);
})

router.get('/searchQuestion/:type/:topic/:query',async(req,res)=>{
    var type = req.params.type;
    var topic = req.params.topic;
    var query = req.params.query;

    switch(type){
      case 'BECE School':
        type = 4;
        break;
      case 'WASSCE School':
        type = 2;
        break;
      case 'WASSCE Private':
        type = 1
        break;
      default:
        type = 3;
        break;
    }

    var questions;
    if(topic == 'Everywhere'){
      questions = await connect.select('*').from('quetions').leftJoin('topic','quetions.topic','topic.t_id').where('quetions.exam_type','=',type).andWhere('quetions.question','like','%'+query+'%').limit(10);
    }else{
      questions = await connect.select('*').from('quetions').leftJoin('topic','quetions.topic','topic.t_id').where('quetions.exam_type','=',type).andWhere('topic.topic','=',topic).andWhere('quetions.question','like','%'+query+'%').limit(10);
    }

  res.status(200).send(questions);
})


async function getTable(year){
  var year = await connect.select('*').from('current_year').where('year','=',year);

  var table = 'quetions';
  if(year.length > 0){
    table = 'future_questions';
  }
  return table;
}

module.exports = router;
