function populateForm( json ) {
	// Print json to the log; might need it for troubleshooting later if element numbers change
	console.log(json);
	// Update response json to contain desired default values
	json[0].defaultValue = region_name;
	json[1].defaultValue = EC2Type;
	json[2].defaultValue = EC2Size;
	json[3].defaultValue = CourseType;
	
	// Use the API to build the form items
	FMEServer.generateFormItems( "example-form", json );

	// Add the custom submit button
	var button = document.createElement( "input" );
	button.id = "RequestButton";
	button.type = "button";
	button.value = "Request Virtual Machine";
	button.setAttribute( "onclick", "submitJob();" );
	form.appendChild( button );

	//Add job results section
	var hr = document.createElement( "hr" );
	var div = document.createElement( "div" );
	div.id = "jobResult";
	div.innerHTML = "<h1> </h1>";
	form.appendChild( hr );
	form.appendChild( div );

}
function callback( json ) {

	var resultText = json.status;
	var resultId = json.id;

	//Enable the request button again
	var button = document.getElementById("RequestButton");
	button.disabled = false;	

	//Show job results
	var div = document.getElementById("jobResult");
	if(resultText == 'SUCCESS'){
		div.innerHTML = "<h4>Email Sent! Request ID is "+resultId+"<br> Follow the additional instructions in the email. <br>If you do not receive an email within 5 minutes, please double-check the email address above, and check your spam filter</h4>";
	}
	else if(json.statusMessage == "Parameter 'FullName' must be given a value.\n    "){
		div.innerHTML = "<h4>Request failed <br>You must enter your full name and email address <br> Please try again</h4>";
	}
	else if(json.statusMessage == "Parameter 'EmailAddress' must be given a value.\n    "){
		div.innerHTML = "<h4>Request failed <br>You must enter your full name and email address <br> Please try again</h4>";
	}
	else if(json.statusMessage == "Terminator: Termination Message: 'Invalid email address'"){
		div.innerHTML = "<h4>Request failed <br>Invalid Email Address<br> Please check your email address and try again <br>Request ID is "+resultId+"</h4>";
	}
	else{
		div.innerHTML = "<h4>Something has gone wrong <br> Contact train@safe.com and include the following information:</h4><pre>"+JSON.stringify(json, undefined, 4)+"</pre>";
	}
}

function submitJob() {
	// Create the the publishedParameters array, and a checkboxes object
	var params = { "publishedParameters" : [] };
	var publishedParameters = params.publishedParameters;
	var checkboxes = {};

	//Disable the request button so it doesn't get pressed again
	var button = document.getElementById("RequestButton");
	button.disabled = true;

	//Show spinner
	var div = document.getElementById("jobResult");
	div.innerHTML = '<img src="https://s3.amazonaws.com/fmevm/images/FMEServerLoader.gif" alt="Requesting Virtual Machine. Please Wait.">'

	// Loop through the form elements and build the publishedParameters array
	for( var i = 0; i < form.elements.length; i++ ){
		var element = form.elements[i];
		var obj = { "name" : "", "value" : null }
		obj.name = element.name;
		if( element.type == "select" ) {
			obj.value = element[element.selectedIndex].value;
			publishedParameters.push( obj );
		} else if( element.type == "checkbox" ){
			if( element.checked ) {
				if( !checkboxes[element.name] ){
					checkboxes[element.name] = [];
				}
				checkboxes[element.name].push( element.value );
			}
		} else if( element.type != "hidden" && element.type != "button" ) {
			obj.value = element.value;
			publishedParameters.push( obj );
		}
	}
	// Add all grouped checkbox elements to the published parameters
	for( name in checkboxes ) {
		publishedParameters.push( { "name" : name, "value" : checkboxes[name] } );
	}
	// Submit Job to FME Server and run synchronously
	FMEServer.submitSyncJob( repository, workspace, params, callback );
}

