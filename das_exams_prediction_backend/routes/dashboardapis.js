var express = require('express');
var md5 = require('md5');
var moment = require('moment');
var connect = require('./includes/connect');
var router = express.Router();
const csv=require('csvtojson')
const fs = require('fs')

router.post('/login',async(req,res)=>{
    var email = req.body.email;
    var password = md5(req.body.password);

    var userData = await connect.select('*').from('adminusers').where({email: email,password:password});

    if(userData.length > 0){
        req.session.userData = userData[0];
        res.redirect('/dash/app');
    }else{
        req.session.message = {
            message: 'Incorrect email/password provided',
            type:'danger'
        }
        res.redirect('/dash/');
    }
})

router.get('/dashbaordstat',async(req,res)=>{

    var data = await connect.select('*').count('user_id',{as: 'total'}).from('users').where('joined_date','>=',new Date().getFullYear()+'-01-01').andWhere('joined_date','<=',new Date().getFullYear()+'-12-31').groupByRaw('month(joined_date),typeOfExams');

    var userRegistration = [
        ['Month', 'BECE Students', 'WASSCE Students'],
    ];

    var months = [];
    data.forEach(users => {
        var dbMonth = moment(users.joined_date).format('MMMM');
        var found = months.filter(e => e.name === dbMonth);
       
        if(found.length == 0){
            months.push(
                {
                    name: dbMonth,
                    bece:users.typeOfExams == 'BECE' ? users.total : 0,
                    wassce: users.typeOfExams == 'BECE' ? 0 : users.total
                }
            );
        }else{
            for (let index = 0; index < months.length; index++) {
                if(months[index].name == found[0].name){
                    if(users.typeOfExams == 'BECE'){
                        months[index].bece = users.total;
                    }else{
                        months[index].wassce = users.total;
                    }
                    break;
                }
            }
            
        }
    });
    
    months.forEach(data => {
        var nData = [data.name, data.bece, data.wassce];
        userRegistration.push(nData);
    });

    var data = await connect.select('*').count('user_id',{as: 'total'}).from('users').groupBy('typeOfExams');
    var totalUsers = [
        ['Students', 'Total']
    ];
    data.forEach(users => {
        totalUsers.push(
            [users.typeOfExams+' Students', users.total]
        )
    });
    

    var data = await connect.select('*').from('submitted_questions').leftJoin('f_answers','submitted_questions.sq_id','f_answers.question_id').where('.date','>=',new Date().getFullYear()+'-01-01').andWhere('.date','<=',new Date().getFullYear()+'-12-31');

    var submitted_questions = [
        ['Month', 'Total', 'Pending', 'Answered']
    ];

    var months = [];
    data.forEach(questions => {
        var dbMonth = moment(questions.date).format('MMMM');
        var found = months.filter(e => e.month === dbMonth);
        if(found.length == 0){
            months.push({
                    month: dbMonth,
                    total:0,
                    pending:0,
                    answered: 0
            });
        }
    });

    data.forEach(questions => {
        var dbMonth = moment(questions.date).format('MMMM');
        for (let index = 0; index < months.length; index++) {
            if(months[index].month == dbMonth){
                months[index].total += 1;
                if(questions.a_text == null){
                    months[index].pending += 1;
                }else{
                    months[index].answered += 1;
                }
                break;
            }
        }
    })
    
    months.forEach(quetions => {
        var nData = [quetions.month, quetions.total, quetions.pending,quetions.answered];
        submitted_questions.push(nData);
    });
    var data = {
        userRegistration: userRegistration,
        totalUsers: totalUsers,
        submitted_questions:submitted_questions
    }
    res.status(200).send(data);
})

router.post('/add-subject',async(req,res)=>{
    var subject_name = req.body.subject_name;
    //check if subject already exist
    var data = await connect('subject').where({subject: subject_name});
    if(data.length > 0){
        req.session.message = {
            message: `${subject_name}  already exist`,
            type:'danger'
        }
        res.redirect('/dash/app/add-subjects');
        return;
    }else{
        await connect.insert({subject:subject_name}).into('subject');
        req.session.message = {
            message: `${subject_name} added`,
            type:'success'
        }
        res.redirect('/dash/app/subjects');
        return;
    }
})

router.post('/edit-subject',async(req,res)=>{
    var subject_name = req.body.subject_name;
    //check if subject already exist
    var data = await connect('subject').where({subject: subject_name}).andWhere('sub_id','<>',req.body.sub_id);
    if(data.length > 0){
        req.session.message = {
            message: `${subject_name}  already exist`,
            type:'danger'
        }
        res.redirect('/dash/app/subject/'+req.body.sub_id+'/edit');
        return;
    }else{
        await connect('subject').update({subject:subject_name}).where('sub_id','=',req.body.sub_id);
        req.session.message = {
            message: `${subject_name} updated`,
            type:'success'
        }
        res.redirect('/dash/app/subjects');
        return;
    }
})

router.get('/subject/:id/delete',async(req,res)=>{
    var id = req.params.id;
    var responseData = await connect('subject').where({sub_id: id});
    if(responseData.length < 1){
        res.redirect('/error');
        return;
    }

    var topics = await connect('topic').where({subject: id});
    if(topics.length > 0){
        req.session.message = {
            message: `${responseData[0].subject} has some topics`,
            type:'danger'
        }
        res.redirect('/dash/app/subjects');
        return;
    }

    await connect('subject').where({sub_id: id}).del();
    req.session.message = {
        message: `${responseData[0].subject} deleted`,
        type:'success'
    }
    res.redirect('/dash/app/subjects');
    return;
})


router.get('/subject/topic/:id/delete',async(req,res)=>{
    var id = req.params.id;
    var responseData = await connect.raw('select *, subject.subject as subject_name from topic left join subject on topic.subject = subject.sub_id where topic.t_id = ?',[id]);
    if(responseData.length < 1){
        res.redirect('/error');
        return;
    }

    var topics = await connect('quetions').where({topic: id});
    if(topics.length > 0){
        req.session.message = {
            message: `${responseData[0][0].topic} has some questions`,
            type:'danger'
        }
        res.redirect(`/dash/app/subject/${responseData[0][0].sub_id}/topics`);
        return;
    }

    await connect('topic').where({t_id: id}).del();
    req.session.message = {
        message: `${responseData[0][0].topic} deleted`,
        type:'success'
    }
    res.redirect(`/dash/app/subject/${responseData[0][0].sub_id}/topics`);
    return;
})

router.post('/add-topic',async(req,res)=>{
    var subject_id = req.body.sub_id;
    var topic = req.body.topic_name;

    //check if topic already exist
    var data = await connect('topic').where({subject: subject_id, topic: topic});
    if(data.length > 0){
        req.session.message = {
            message: `${topic}  already exist`,
            type:'danger'
        }
        res.redirect('/dash/app/add-topics/'+subject_id);
        return;
    }else{
        await connect.insert({subject:subject_id, topic: topic}).into('topic');
        req.session.message = {
            message: `${topic} added`,
            type:'success'
        }
        res.redirect(`/dash/app/subject/${subject_id}/topics`);
        return;
    }
})

router.post('/edit-topic',async(req,res)=>{
    var subject_id = req.body.sub_id;
    var topic = req.body.topic_name;
    var topic_id = req.body.topic_id;

    //check if subject already exist
    var data = await connect('topic').where({topic: topic}).andWhere('t_id','<>',topic_id).andWhere('subject','=',subject_id);
    if(data.length > 0){
        req.session.message = {
            message: `${topic}  already exist`,
            type:'danger'
        }

      
        res.redirect('/dash/app/subject/topic/'+topic_id+'/edit');
        return;
    }else{
        await connect('topic').update({topic:topic}).where('t_id','=',topic_id);
        req.session.message = {
            message: `${topic} updated`,
            type:'success'
        }
        res.redirect(`/dash/app/subject/${subject_id}/topics`);
        return;
    }
})

router.get('/getSubjectTopics/:id',async(req,res)=>{
    var id = req.params.id;
    var data = await connect.select('*').from('topic').where({subject: id});
    res.status(200).send(data);
})

router.post('/add-question',async(req,res)=>{

    if(req.files){
    if(req.files.questions_file){
        var file = req.files.questions_file;
        var exts = ['csv'];
        var ext = file.name.split('.');
        ext = ext[ext.length-1];
        if(exts.indexOf(ext) < 0){
            res.status(201).send('Please upload a valid csv file');
            return;
        }

        var path = __dirname+'/csv/'+moment(new Date()).format('YYYY_m_d_H_s_x')+'_'+file.name;
        await file.mv(path);
        
        const row = await csv().fromFile(path);
        await fs.unlinkSync(path);
        
        for(var i=0; i<row.length; i++){
            if(row[i].a_video.trim().length > 0){
                if(!ytVidId(row[i].a_video)){
                    res.status(201).send(`Error on row ${i+1}, invalid youtube link`);
                    return;
                    break;
                }

            }
            if(row[i].a_photo.trim().length > 0){
                if(!validateFile({name: row[i].a_photo})){
                    res.status(201).send(`Error on row ${i+1}, invalid answer picture`);
                    return;
                    break;
                }
            }
            if(row[i].q_photo.trim().length > 0){
                if(!validateFile({name: row[i].q_photo})){
                    res.status(201).send(`Error on row ${i+1}, invalid question picture`);
                    return;
                    break;
                }
            }
            row[i].future = 0;
            row[i].views = 0;
            row[i].year = req.body.year;
            row[i].type = req.body.type;
            row[i].exam_type = req.body.exam_type;
            row[i].subject = req.body.subject;
            row[i].topic = req.body.topic;

            var answerData = {
                a_text: row[i].a_text,
                a_video: row[i].a_video,
                a_photo: row[i].a_photo
            };
        
            delete(row[i].a_video);
            delete(row[i].a_text);
            delete(row[i].a_photo);

            try{
                var responseData = await connect('quetions').insert(row[i]).returning('q_id');
                answerData.question_id = responseData[0];
                var d = await connect('answers').insert(answerData);
            }catch(e){
                res.status(201).send('An error occured');
                return;
            }
        }

        res.status(200).send('bulk question');
        return;
    }
}
    
    if(req.body.a_video.trim().length > 0){
        if(!ytVidId(req.body.a_video)){
            res.status(201).send('Invalid youtube link');
            return ;
        }
    }

    if(req.files){
        if(req.files.q_photo){
            if(!validateFile(req.files.q_photo)){
                res.status(201).send('Question picture should be a valid image');
                return;
            }

            var document = req.files.q_photo;
            var filename = moment(new Date()).format('YYYY_m_d_h_s_x')+'_'+req.files.q_photo.name;
            var uploadPath = `public/uploads/images/question_${filename}`;
            req.body.q_photo = `https://dasexamprediction.biztrustgh.com/uploads/images/question_${filename}`;
            await document.mv(uploadPath);
        }else{
            if(req.body.edit == 'false'){
                req.body.q_photo = '';
            }
        }
        if(req.files.a_photo){
            if(!validateFile(req.files.a_photo)){
                res.status(201).send('Answer picture should be a valid image');
                return;
            }

            var document = req.files.a_photo;
            var filename = moment(new Date()).format('YYYY_m_d_h_s_x')+'_'+req.files.a_photo.name;
            var uploadPath = `public/uploads/images/answer_${filename}`;
            req.body.a_photo = `https://dasexamprediction.biztrustgh.com/uploads/images/answer_${filename}`;
            await document.mv(uploadPath);
        }else{
            if(req.body.edit == 'false'){
                req.body.q_photo = '';
            }
        }
    }else{
        if(req.body.edit == 'false'){
            req.body.q_photo = '';
            req.body.a_photo = '';
        }
    }

    
    //upload and insert question with it's answer
    var answerData = {
        a_text: req.body.a_text,
        a_video: req.body.a_video,
        a_photo: req.body.a_photo
    };

    delete(req.body.a_video);
    delete(req.body.a_text);
    delete(req.body.a_photo);

    req.body.future = 0;
    req.body.views = 0;
    
    if(req.body.edit == 'true'){
        delete(req.body.edit);
        await connect('quetions').update(req.body).where({q_id: req.body.q_id})
        await connect('answers').update(answerData).where({question_id: req.body.q_id})
        res.status(201).send('Question Updated');
    }else{
        delete(req.body.edit);
        var responseData = await connect('quetions').insert(req.body).returning('q_id');
   
        answerData.question_id = responseData[0];
        var d = await connect('answers').insert(answerData);
    }
    

    function ytVidId(url) {
        console.log(url);
        var p = /^(?:https?:\/\/)?(?:www\.)?youtube\.com\/watch\?(?=.*v=((\w|-){11}))(?:\S+)?$/;
        return (url.match(p)) ? RegExp.$1 : false;
    }

    function validateFile(file){
        var exts = ['png','PNG','JPEG','jpg','JPG','jpeg'];
        var ext = file.name.split('.');
        
        ext = ext[ext.length-1];
        console.log(ext);
        
        if(exts.indexOf(ext) < 0){
            return false;
        }
        return true;
    }
    res.status(200).send('okay');
})

router.post('/submit_answer',async(req,res)=>{
    if(req.files){
        if(req.files.a_photo){
            if(!validateFile(req.files.a_photo,'pic')){
                req.session.message = {
                    message: "Please select a valid image",
                    type:"danger"
                }
                res.redirect('/dash/app/s_question/'+req.body.id+'/view');
                return;
            }else{
                var filename = moment(new Date()).format('YYYY_m_d_h_s_x')+'_'+req.files.a_photo.name;
                var uploadPath = `public/uploads/images/sq_answer_${filename}`;
                req.files.a_photo.mv(uploadPath);
                req.body.a_photo = `https://dasexamprediction.biztrustgh.com/uploads/images/sq_answer_${filename}`;
            }
        }else{
            req.body.a_photo = '';
        }

        if(req.files.file){
            if(!validateFile(req.files.file,'doc')){
                req.session.message = {
                    message: "Please select a valid document",
                    type:"danger"
                }
                res.redirect('/dash/app/s_question/'+req.body.id+'/view');
                return;
            }else{
                var filename = moment(new Date()).format('YYYY_m_d_h_s_x')+'_'+req.files.file.name;
                var uploadPath = `public/uploads/docs/sq_answer_${filename}`;
                req.files.file.mv(uploadPath);
                req.body.file = 'sq_answer_'+filename;
            }
        }else{
            req.body.file = '';
        }
    }else{
        req.body.a_photo = '';
        req.body.file = '';
    }

    if(req.body.a_video != ''){
        if(!ytVidId(req.body.a_video)){
            req.session.message = {
                message: "You provided an invalid youtube video link",
                type:"danger"
            }
            res.redirect('/dash/app/s_question/'+req.body.id+'/view');
            return;
        }
    }

    if(req.body.a_text == '' && req.body.a_video == '' && !req.files){
        req.session.message = {
            message: "Please provide at least one answer",
            type:"danger"
        }
        res.redirect('/dash/app/s_question/'+req.body.id+'/view');
        return;
    }
    //check if question has an answer
    var data = await connect.select('*').from('f_answers').where({question_id: req.body.id});

    var sdata = {
        question_id : req.body.id,
        qa_file: req.body.file,
        a_video: req.body.a_video,
        a_photo: req.body.a_photo,
        a_text: req.body.a_text
    }
    if(data.length > 0){
        if(req.body.a_video == ''){
            delete (sdata.a_video);
        }
        if(req.body.qa_file == ''){
            delete (sdata.qa_file);
        }
        if(req.body.a_photo == ''){
            delete (sdata.a_photo);
        }
        if(req.body.a_text == ''){
            delete (sdata.a_text);
        }
        await connect('f_answers').update(sdata).where({question_id: req.body.id});
    }else{
        await connect('f_answers').insert(sdata);
    }
    await connect('submitted_questions').update({status: 'answered'}).where({sq_id: req.body.id});
    req.session.message = {
        message: "Question answer updated",
        type:"success"
    }
    res.redirect('/dash/app/s_question/'+req.body.id+'/view');


    function ytVidId(url) {
        console.log(url);
        var p = /^(?:https?:\/\/)?(?:www\.)?youtube\.com\/watch\?(?=.*v=((\w|-){11}))(?:\S+)?$/;
        return (url.match(p)) ? RegExp.$1 : false;
    }

    function validateFile(file,type){
        var exts = ['png','PNG','JPEG','jpg','JPG','jpeg'];
        if(type == 'doc'){
            exts = ['docx','pdf','xlsx'];
        }
        var ext = file.name.split('.');
        
        ext = ext[ext.length-1];
        
        if(exts.indexOf(ext) < 0){
            return false;
        }
        return true;
    }

})

router.post('/update_user',async(req,res)=>{
  if(req.body.expiration > new Date()){
      req.body.expired = 'false';
  }else{
      req.body.expired = 'true';
  }
  await connect('users').update(req.body).where({user_id: req.body.user_id});
  req.session.message = {
    message: "Expiration updated",
    type:"success"
}
  res.redirect('/dash/app/users/'+req.body.user_id+'/view');
})

router.post('/update_logins',async(req,res)=>{

    req.body.password = md5(req.body.password);
    await connect('adminusers').update(req.body);
    req.session.message = {
        message: "Logins updated",
        type:"success"
    }
    res.redirect('/dash/app/settings');
})

router.post('/update_subscription',async(req,res)=>{
    if(isNaN(req.body.monthly) || isNaN(req.body.yearly)){
        req.session.message = {
            message: "Please input valid amounts",
            type:"danger"
        }
        res.redirect('/dash/app/settings');
        return;
    }
    await connect('upgrade_amount').update(req.body);
    req.session.message = {
        message: "Subscription Pacakges updated",
        type:"success"
    }
    res.redirect('/dash/app/settings');
})

router.post('/update_year',async(req,res)=>{
    if(req.body.year < new Date().getFullYear()){
        req.session.message = {
            message: "Invalid year provided",
            type:"danger"
        }
        res.redirect('/dash/app/settings');
        return;
    }
    await connect('current_year').update(req.body);
    req.session.message = {
        message: "Current Year updated",
        type:"success"
    }
    res.redirect('/dash/app/settings');
})

router.get('/question/:id/delete',async(req,res)=>{
    var id = req.params.id;
    await connect('quetions').where({q_id: id}).del();
    await connect('answers').where({question_id: id}).del();
    req.session.message = {
        message: "Question deleted successfully",
        type:"success"
    }

    req.query.url = req.query.url.split('=');
    req.query.url = req.query.url[1];
    res.redirect(`/dash/app/view-questions?type=${req.query.url}&topic=${req.query.topic}&year=${req.query.year}&section=${req.query.section}&exam_type=${req.query.exam_type}&topic_name=${req.query.topic_name}&subject_name=${req.query.subject_name}`);
})
module.exports = router;