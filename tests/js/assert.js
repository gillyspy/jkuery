/* jslint browser:true */
/* global window:true, jQuery:true, document:true ,console:true*/

var results, assert, test, document;

document = window.document;

assert = function assert(value, desc) {
  var li = document.createElement("li");
  li.className = value ? "pass" : "fail";
  li.appendChild(document.createTextNode(desc));
  results.appendChild(li);
  if (!value) {
    li.parentNode.parentNode.className = "fail";
  }
  console.log(desc, ':', !! value);
  if(arguments.length > 2){
    console.log.apply(console,Array.prototype.slice.call(arguments,2));
  }
  
  return li;
};

test = function test(name, fn) {
  results = document.getElementById("results");
  results = assert(true, name).appendChild(
    document.createElement("ul"));
  fn();
};

