var knex = require('knex')({
    client: 'mysql',
    connection: {
      host : 'localhost',
      user : 'root',
      password : '',
      database : 'das_exams_prediction'
    }
    //  connection: {
    //   host : 'premium14.web-hosting.com',
    //   user : 'biztxsie_biztrustgh_user',
    //   password : 'BJS6!)7V44Wq',
    //   database : 'biztxsie_das_exams_prediction'
    // }
  });

  module.exports = knex;