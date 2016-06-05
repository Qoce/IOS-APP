var http = require("http");
var fs = require('fs');

var storedLocationsLong = new Array();

var server = http.createServer(function(request, response) {
    
    console.log('Connection made to');
    console.log(request.url);
    
    var url = request.url;
    
    // URL MESSAGES THAT CAN BE SENT
    // GET: /gminLong?maxLong?minLat?maxLat gets all of the locations in the array that are within the boundaries specified by the numbers
    // SET: /sLONG?LAT?GENDER?AGE adds a new item to the array
    if(url.charAt(1)==='g') {
        var values = parseRequest(url.slice(2,url.size),'g');
        if(Math.abs((values[1]-values[0]) *(values[3] - values[2])) > 100){
            response.write("[]")
        }
        else{
            response.write(JSON.stringify(getLocationsInRange(values[0],values[1],values[2],values[3],storedLocationsLong)));
        }
    }
    else if(url.charAt(1)==='s') {
        var values = parseRequest(url.slice(2,url.size),'s');
        var obj = addObject({latitude: values.latitude, longitude: values.longitude, ageAvg: values.ageAvg, percentMale: values.percentMale, pop: values.pop, title: values.title},true);
        console.log(JSON.stringify(obj))
        response.write(JSON.stringify(obj));
        setTimeout(addObject, 9000, {latitude: values.latitude, longitude: values.longitude, ageAvg: values.ageAvg, percentMale: values.percentMale, pop: -values.pop, title: values.title}, true);
        console.log("Does this run inmediatally?");
    }
    else if(url.charAt(1)==='p') {
        response.write(JSON.stringify(storedLocationsLong));
    }
    response.end();
    
});

//fs.readFile('./testdatalat.json', 'utf-8', function(err,data){
//    data = JSON.parse(data);
//    storedLocationsLat = data;
//});
//fs.readFile('./testdatalong.json', 'utf-8', function(err,data){
//    data = JSON.parse(data);
//    storedLocationsLong = data;
//});
/*
Adds the refrenced object to the latitude and longitude arrays at the specified location
*/
function addObject(obj,sort){

    var longIndex; 
    if(sort) {
        longIndex = findObj(obj);
    }
    if(longIndex != -1 && sort){
        
        var storedObj = storedLocationsLong[longIndex];
        var newPop = storedObj.pop + obj.pop;
        
        if(newPop === 0) {
            storedLocationsLong.splice(longIndex, 1);
            return null;
        }
        var males = storedObj.pop * storedObj.percentMale;
        males += obj.percentMale * obj.pop;
        storedObj.percentMale = males / newPop;
           
        var age = storedObj.ageAvg * storedObj.pop;
        age += obj.ageAvg * obj.pop;
        storedObj.ageAvg = age / newPop;
        storedObj.pop = newPop; //F FINDER
        
        
        return storedObj;
        
    }
    else {
        storedLocationsLong.push({latitude: obj.latitude, longitude: obj.longitude, ageAvg: obj.ageAvg, percentMale: obj.percentMale, pop: obj.pop, title: obj.title});
    }
    if(sort){
        storedLocationsLong.sort(function(a,b){
            return a.longitude-b.longitude; 
        });
    }
    return(obj);
}

function findObj(obj){
    var array = storedLocationsLong;

    for(var i = 0; i < array.length; i++){
        if(isEqual(obj,array[i])) return i;   
    }
    return -1;
}
function isEqual(obj1, obj2){
    if(obj1.latitude !== obj2.latitude) return false;
    if(obj1.longitude !== obj2.longitude) return false;
    return true;
}
function writeData(longitude, latitude, age, gender, fileToAdd){
    
    var i = {longitude: longitude, latitude: latitude, age: age, gender: gender};
    
    fs.appendFile(fileToAdd,JSON.stringify(i), function(err){
        if(err) throw err;
        console.log('Data written');    
    });
    
}

function printLocationArrays(){
    console.log(storedLocationsLong.length);
    for(var i = 0; i < storedLocationsLong.length; i++){
       console.log(JSON.stringify(storedLocationsLong[i]));   
    }
}

function getLocationsInRange(minLong, maxLong, minLat, maxLat, array){
    console.log(minLong, maxLong, minLat, maxLat);
    
    var rangeLong = getRangeInArray(minLong, maxLong, array);
    var longs = array.slice(rangeLong.min,rangeLong.max);
    
    var combined = new Array();
    
    console.log(JSON.stringify(rangeLong));
    
    for(var i = 0; i<longs.length; i++){
        if(longs[i].latitude >= minLat && longs[i].latitude <= maxLat){
            combined.push(longs[i]);
        }
    }
    return combined;
}
/*
* returns the square of the distance between two points.  This is based of of pythagorean theorm for triangles under the assumption that the distance from the two points are small
* enough such that the curveture of the earth is negligable.
*/
function getSquaredDistance(long, lat, long2, lat2){
    return (long - long2) * (long - long2) + (lat - lat2) * (lat - lat2);   
}
function getRangeInArray(min, max, array){
    var low = findFirstAfter(min, array);
    var high = findFirstAfter(max, array);
    console.log(low, high);
    return new minMax(low,high);
}

function findFirstAfter(num, array){
    var low = 0;
    var high = array.length - 1;
    
    if(num < array[low].longitude){
        console.log('too low');
        return low;
    }
    else if (num > array[high].longitude){
        console.log('too high');
        console.log(array[high].longitude);
        return high;   
    }
    
    while(true){
        var mid = Math.floor((low + high)/2);
        if(array[mid].longitude <= num) low = mid;
        else high = mid; 
        if(high - low === 1) return high;
    }
}

function minMax(min, max){
    this.min = min;
    this.max = max;
}
// Longitude is first in requests
function parseRequest(str,id){
    var values = new Array();
    var currentChar = 0;
    
    
    if(id === 'g' || values === 'j'){
        var max = 4;
        if(values === 'j') {
            max = 2;
        }
        for(var i = 0;i < 4; i++){
            var number = "";
            while(currentChar!==str.length&&str[currentChar]!=='?'){
                number = number.concat(str[currentChar]);
                currentChar++;
            }
            currentChar++;
            values.push(parseFloat(number));
        }
        
        return values;
    }
    else if(id === 's' || id === 'r'){
        var age;
        var gender;
        var latitude
        var longitude;
        var title;
        
        for(var i = 0;i < 5; i++){
            var number = "";
            while(currentChar!==str.length&&str[currentChar]!=='?'){
                number = number.concat(str[currentChar]);
                currentChar++;
            }
            currentChar++;
            switch(i){
                case 0:
                    longitude = parseFloat(number);
                    break;
                case 1:
                    latitude = parseFloat(number);
                    break;
                case 2:
                    gender = number;
                    break;
                case 4:
                    number = number.replace(/_/g,' ');
                    title = number;
                    break;
                default:
                    age = parseInt(number);
                    break;
            }   
        }
        if(age < 0 || age > 105) return -1;
        if(gender !== 'f' && gender !== 'm') return -1;
        
        var percentMale;
        if(gender === 'f') percentMale = 0.0;
        else if (gender === 'm') percentMale = 100.0;
        
        return {latitude: latitude, longitude: longitude, ageAvg: age, percentMale: percentMale, pop: 1, title: title};
    }
}

// Creates an array grid of fake locations that were tagged to show the locaitons of various people 
function createFakeData(){
    console.log('creating fake data');
    
    for(var i = 0; i < 1000; i++){
        for(var j = 0; j < 1000; j++){
            addObject({longitude: Math.round((i * 360 / 1000 - 180) * 10000000) / 10000000, latitude: Math.round((j * 180 / 1000 - 90) * 10000000) / 10000000, ageAvg: 20, percentMale: 0.0, pop: 1, title: "qwertyuiop"},false);
        }
        console.log(i);
    }
    storedLocationsLong.sort(function(a,b){
       return a.longitude-b.longitude; 
    });
}

createFakeData(); //Creates the data used to test the app
server.listen(PORT_NUMBER_HERE);
console.log("Server is listening");
