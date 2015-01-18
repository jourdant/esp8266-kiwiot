function read(query, user, request) {
	//check if sensor_id was passed in by the query string
    if (request.parameters.sensor_id)
    {
		//get table with temperature data
        var table = tables.getTable("temperature");
        if (table) {
			//run query on tabloe
            table.select("__createdAt", "sensor_id", "temperature")
                 .where({ sensor_id: request.parameters.sensor_id })
                 .orderByDescending("__createdAt")
                 .take(1)
                 .read({ success: function(result) {
					//return most recent temperature reading
					if (result && result.length >= 1) {
						request.respond(statusCodes.OK, result[0]);
					}
					//if there isn't a reading for the given id, return an empty object
					else {request.respond(statusCodes.OK, {});}
             }});
        }
    }
	//if no sensor_id passed in, return default table query
    else { request.execute(); }
}