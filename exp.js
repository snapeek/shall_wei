javascript:($(function() {
var exec = function(){
  window.dflag = true;
  // stk.attributealldata();
  // stk.keywordzone();
  stk.getchartdata();
};
if(typeof(stk) == "undefined") {
window.dflag = false;
STK.register("comp.hotfeed", function(stk) {

  var names = {heilongjiang:"黑龙江",jilin:"吉林",liaoning:"辽宁",hebei:"河北",shandong:"山东",jiangsu:"江苏",zhejiang:"浙江",anhui:"安徽",henan:"河南",shanxi:"山西",shaanxi:"陕西",gansu:"甘肃",hubei:"湖北",jiangxi:"江西",fujian:"福建",hunan:"湖南",guizhou:"贵州",sichuan:"四川",yunnan:"云南",qinghai:"青海",hainan:"海南",shanghai:"上海",chongqing:"重庆",tianjin:"天津",beijing:"北京",ningxia:"宁夏",neimongol:"内蒙古",guangxi:"广西",xinjiang:"新疆",xizang:"西藏",guangdong:"广东",hongkong:"香港",taiwan:"台湾",macau:"澳门"}
  var to_csv = function(str, name, i)  
  {  
    aLink = $(".bottom-link a")[i];
    str =  encodeURIComponent(str);
    download = $("p.search-word").text() + "-" + name + ".csv";
    aLink.href = "data:text/csv;charset=gb2312,\ufeff"+str;  
    $(aLink).attr("download", download);
    aLink.click();  
  }  

  var getchartdata = function() {
    stk.core.io.ajax(
      {
        url:"/index/ajax/getchartdata",
        args:{month:12},
        method:"get",
        onComplete:function (an) {
          var zt_str = "";
          for (var item in an.data[0].zt) {
            item = an.data[0].zt[item];
            zt_str += (item.day_key + "," + item.value + "\n" );         
          };
          to_csv(zt_str, "提及量统计", 4);
        }

      }
    )
  }

  var keywordzone = function(){
    // document.cookie.match(/ALF=(\d+)/)[1]
    stk.core.io.ajax(
      {
        url:"/index/ajax/keywordzone",
        args:{type:"default",wid:"4uKh7Yhbwn7o"},
        method:"get",
        onComplete:function(an) {
          // console.log(an);
          window.aa = an;
          var zone_str = "";
          for (var item in an.zone) {
            val = an.zone[item].value
            zone_str += (names[item] + "," + val + "\n" );
          };
          to_csv(zone_str, "地域热议度", 0);
          var user_str = "";
          for (var item in an.user) {
            val = an.user[item].value
            user_str += (names[item] + "," + val + "\n" );
          };
          to_csv(user_str, "用户热议度", 1);
        }
      }
    );
  };
  var attributealldata = function() {
    stk.core.io.ajax(
      {
        url:"/index/ajax/getdefaultattributealldata",
        args:{},
        method:"get",
        asynchronous:false,
        onComplete:function(w){
          console.log(w);
          var age_str = "";
          for (var item in w.data.age.key2[0]) {
            age_str += (item + "," + w.data.age.key2[0][item] + "\n" );
          };
          to_csv(age_str, "年龄", 2);
          var sex_str = "";
          for (var item in w.data.sex.key2) {
            sex_str += (item + "," + w.data.sex.key2[item] + "\n" );
          };
          to_csv(sex_str, "性别", 3);
        }
      }
    );
  };
  window.stk = {
    attributealldata: attributealldata,
    keywordzone:keywordzone,
    getchartdata:getchartdata
  };
  exec();
  return window.stk;
});
}
else {
    console.log(window.dflag);
  if(window.dflag){
    if (confirm("已经下载或者正在下载, 是否重新下载")) {
      exec();
    };
  }
  else {
    exec();
  }
};
}));

