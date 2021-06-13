var express = require('express');
var connect = require('./includes/connect');
var router = express.Router();
var moment = require('moment');

//middlewares
router.use(function (req, res, next) {

    var authPages = ['/api/login','/'];
    if(authPages.indexOf(req.url) > -1){
        if(req.session.userData){
            res.redirect('/dash/app');
            return;
        }
    }else{
        if(!req.session.userData){
            res.redirect('/dash/');
            return;
        }
    }
    next()
})

router.get('/',async(req,res)=>{
    var data = Object.assign({},req.session);
    delete (req.session.message);
    res.render('dash/login',{layout:"auth",title:"Login",data:data});
})

router.get('/app',async(req,res)=>{
    var data = Object.assign({},req.session); 
    var allUsers = await connect.select('*').from('users');
    var premiumUsers = await connect.select('*').from('users').where('expiration','>',new Date());
    var premiumUsers = await connect.select('*').from('users').where('expiration','>',new Date());
    var submitted_questions = await connect.select('*').from('submitted_questions');
    var mostyViewedQuestions = await connect.select('*').from('quetions').leftJoin('exam_type','quetions.exam_type','exam_type.e_id').leftJoin('subject','quetions.subject','subject.sub_id').groupByRaw('quetions.subject,exam_type').orderBy('quetions.views','desc').limit(10);

    data.normalUsers = allUsers.length - premiumUsers.length; 
    data.allUsers = allUsers.length;
    data.premiumUsers = premiumUsers.length;
    data.submittedQuestions = submitted_questions.length;
    data.mostyViewedQuestions = mostyViewedQuestions;

    res.render('dash/index',{layout:"main",title:"Dashboard",data:data});
})

router.get('/app/subjects',async(req,res)=>{
    var data = Object.assign({},req.session); 
    delete (req.session.message);
    data.subjects = await connect.raw("SELECT *,subject.subject as subject_name,count(topic.t_id) as topics FROM `subject` left join topic on topic.subject = subject.sub_id GROUP by subject.sub_id order by subject.sub_id desc");
    data.subjects = data.subjects[0];
    res.render('dash/subjects',{layout:"main",title:"Subjects", data: data});
})

router.get('/app/add-subjects',async(req,res)=>{
    var data = Object.assign({},req.session); 
    delete (req.session.message);
    res.render('dash/add-subjects',{layout:"main",title:"Add Subjects",data:data});
})

router.get('/app/subject/:id/edit',async(req,res)=>{
    var id = req.params.id;
    var data = Object.assign({},req.session); 
    var responseData = await connect('subject').where({sub_id: id});
    if(responseData.length < 1){
        res.redirect('/error');
        return;
    }
    data.subject = responseData[0];
    delete (req.session.message);
    res.render('dash/edit-subject',{layout:"main",title:"Edit Subject",data:data});
})

router.get('/app/subject/:id/topics',async(req,res)=>{
    var id = req.params.id;
    var data = Object.assign({},req.session); 
    var responseData = await connect.raw('select *,count(quetions.q_id) as questions, subject.subject as subject_name,topic.topic as topic_name from topic left join subject on topic.subject = subject.sub_id left join quetions on topic.t_id = quetions.topic where topic.subject = ? group by topic.t_id order by topic.t_id desc',[id]);
    
    data.subject = await connect.select('*').from('subject').where({sub_id: id});
    if(data.subject.length < 1){
        res.redirect('/error');
        return;
    }
    data.subject = data.subject[0];

    data.topics = responseData[0];
    delete (req.session.message);
    res.render('dash/topics',{layout:"main",title:"Topics",data:data});
})

router.get('/app/add-topics/:id',async(req,res)=>{
    var data = Object.assign({},req.session); 
    delete (req.session.message);
    data.subjects =  data.subjects = await connect.raw("SELECT *,subject.subject as subject_name,count(topic.t_id) as topics FROM `subject` left join topic on topic.subject = subject.sub_id where subject.sub_id = ?",[req.params.id]);
    data.subjects = data.subjects[0];
    console.log(data.subjects);
    res.render('dash/add-topics',{layout:"main",title:"Subjects", data: data});
})

router.get('/app/subject/topic/:id/edit',async(req,res)=>{
    var id = req.params.id;
    var data = Object.assign({},req.session); 
    var responseData =  data.subjects = await connect.raw("SELECT *,subject.subject as subject_name,count(topic.t_id) as topics,topic.topic as topic_name FROM `topic` left join subject on topic.subject = subject.sub_id where topic.t_id = ?",[id]);
    if(responseData.length < 1){
        res.redirect('/error');
        return;
    }
    data.subjects = responseData[0];
    delete (req.session.message);
    res.render('dash/edit-topic',{layout:"main",title:"Edit Subject",data:data});
})

router.get('/app/post-question',async(req,res)=>{
    var data = Object.assign({},req.session); 
    data.subjects = await connect.select('*').from('subject');
    delete (req.session.message);
    res.render('dash/post-question',{layout:"main",title:"Post Questions",data:data});
})

router.get('/app/exams',async(req,res)=>{
    var data = Object.assign({},req.session); 
    var exams = await connect.raw("SELECT *,count(quetions.q_id) as questions,subject.subject as subject_name, quetions.type as section  FROM `quetions` left join subject on quetions.subject = subject.sub_id left join topic on quetions.topic = topic.t_id left join exam_type on quetions.exam_type = exam_type.e_id group by quetions.topic, quetions.year, quetions.type,quetions.exam_type order by quetions.q_id desc");
    data.exams = exams[0];
    delete (req.session.message);
    res.render('dash/exams',{layout:"main",title:"Exams",data:data});
})

router.get('/app/view-questions',async(req,res)=>{
    var data = Object.assign({},req.session);
    data.query = req.query;

    var questions = await connect.select('*').from('quetions').where({
        exam_type: req.query.type,
        topic: req.query.topic,
        year: req.query.year,
        type:  req.query.section
    }).leftJoin('answers','quetions.q_id','answers.question_id').orderBy('quetions.q_id','desc');
    data.questions = questions;
    data.url = req.url;
    delete (req.session.message);
    res.render('dash/questions',{layout:"main",title:"Exams",data:data});
})

router.get('/app/exam/question/:id/edit',async(req,res)=>{
    var id = req.params.id;
    var data = Object.assign({},req.session); 
    data.subjects = await connect.select('*').from('subject');
    var d = await connect.select('*').from('quetions').leftJoin('answers','quetions.q_id','answers.question_id').where({q_id: id});
    data.question  = d[0];
    data.topics = await connect.select('*').from('topic').where({subject: data.question.subject});
    delete (req.session.message);
    res.render('dash/edit-question',{layout:"main",title:"Edit Question",data:data});
})

router.get('/app/upcomming-exams',async(req,res)=>{
    var data = Object.assign({},req.session); 
    var year = await connect.select('year').from('current_year');
    var exams = await connect.raw("SELECT *,count(quetions.q_id) as questions,subject.subject as subject_name, quetions.type as section  FROM `quetions` left join subject on quetions.subject = subject.sub_id left join topic on quetions.topic = topic.t_id left join exam_type on quetions.exam_type = exam_type.e_id  where quetions.year = ? group by quetions.topic, quetions.year, quetions.type order by quetions.q_id desc",[year[0].year]);
    data.exams = exams[0];
    delete (req.session.message);
    res.render('dash/upcomming-exams',{layout:"main",title:"Exams",data:data});
})

router.get('/app/an-assignments/:status',async(req,res)=>{
    var data = Object.assign({},req.session); 
    data.questions = await connect.select('*').from('submitted_questions').leftJoin('users','submitted_questions.user_id','users.user_id').where('submitted_questions.status','=',req.params.status).orderBy('submitted_questions.sq_id','desc');
    data.questions.forEach(question => {
        question.date = moment(question.date).format('DD, MMMM YYYY h:m A');
    });
    delete (req.session.message);
    res.render('dash/an-assignments',{layout:"main",title:"Exams",data:data});
})

router.get('/app/s_question',async(req,res)=>{
    var data = Object.assign({},req.session); 
    data.questions = await connect.select('*').from('submitted_questions').leftJoin('users','submitted_questions.user_id','users.user_id').where('submitted_questions.status','=','answered').orderBy('submitted_questions.sq_id','desc');
    data.questions.forEach(question => {
        question.date = moment(question.date).format('DD, MMMM YYYY h:m A');
    });
    delete (req.session.message);
    res.render('dash/an-assignments',{layout:"main",title:"Answered Assignments",data:data});
})

router.get('/app/s_question/:id/view',async(req,res)=>{
    var id = req.params.id;
    var data = Object.assign({},req.session); 
    var responseData = await connect.select('*').from('submitted_questions').leftJoin('users','submitted_questions.user_id','users.user_id').leftJoin('f_answers','submitted_questions.sq_id','question_id').where('submitted_questions.sq_id','=',id);
    data.question = responseData[0];
    data.question.date = moment(data.question.date).format('DD, MMMM YYYY h:m A');
    if(responseData.length < 1){
        res.redirect('/error');
    }
    if(data.question.a_video){
        if(data.question.a_video != ''){
            data.question.a_video = youtube_parser(data.question.a_video);
        }else{
            data.question.a_video = null;
        }
    }

    data.question.a_photo = data.question.a_photo  == '' ? null : data.question.a_photo;

    function youtube_parser(url){
        var regExp = /^https?\:\/\/(?:www\.youtube(?:\-nocookie)?\.com\/|m\.youtube\.com\/|youtube\.com\/)?(?:ytscreeningroom\?vi?=|youtu\.be\/|vi?\/|user\/.+\/u\/\w{1,2}\/|embed\/|watch\?(?:.*\&)?vi?=|\&vi?=|\?(?:.*\&)?vi?=)([^#\&\?\n\/<>"']*)/i;
        var match = url.match(regExp);
        return (match && match[1].length==11)? match[1] : false;
    }
    delete (req.session.message);
    res.render('dash/view-assignment',{layout:"main",title:"Assignment",data:data});
})
router.get('/app/users',async(req,res)=>{
    var data = Object.assign({},req.session); 
    data.users = await connect.select('*').from('users').orderBy('user_id','desc');
    data.users.forEach(user => {
        if(user.expiration >= new Date()){
            user.premium = '<span class="badge badge-success">Premium</span>';
        }else{
            user.premium = '<span class="badge badge-secondary">User</span>';
        }
        user.joined_date = moment(user.joined_date).format('DD, MMMM YYYY h:m A');
        user.expiration = moment(user.expiration).format('DD, MMMM YYYY h:m A');

        
    });
    delete (req.session.message);
    res.render('dash/users',{layout:"main",title:"Users",data:data});
})
router.get('/app/users/:id/view',async(req,res)=>{
    var data = Object.assign({},req.session); 
    var user = await connect.select('*').from('users').where({user_id: req.params.id});
    data.user = user[0];
    if(data.user.length < 1){
        res.redirect('/error');
        return;
    }
    if(data.user.expiration >= new Date()){
        data.user.premium = '<span class="badge badge-success">Premium</span>';
    }else{
        data.user.premium = '<span class="badge badge-secondary">User</span>';
    }
    data.user.joined_date = moment(data.user.joined_date).format('DD, MMMM YYYY h:m A');
    data.user.expiration = moment(data.user.expiration).format('YYYY-MM-DD');
    delete (req.session.message);
    res.render('dash/user',{layout:"main",title:"User",data:data});
})

router.get('/app/settings',async(req,res)=>{
    var data = Object.assign({},req.session); 
    data.subscription = await connect.select('*').from('upgrade_amount');
    data.subscription = data.subscription[0];
    data.currentyear = await connect.select('*').from('current_year');
    data.currentyear = data.currentyear[0].year;
    delete (req.session.message);
    res.render('dash/settings',{layout:"main",title:"Settings",data:data});
})

router.get('/app/logout',async(req,res)=>{
    await req.session.destroy();
    res.redirect('/dash/');
})

module.exports = router;