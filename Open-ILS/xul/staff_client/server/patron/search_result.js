dump('entering patron/search_result.js\n');

if (typeof patron == 'undefined') patron = {};
patron.search_result = function (params) {

	JSAN.use('util.error'); this.error = new util.error();
	JSAN.use('util.network'); this.network = new util.network();
	this.w = window;
}

patron.search_result.prototype = {

	'init' : function( params ) {

		var obj = this;

		obj.session = params['session'];
		obj.query = params['query'];

		JSAN.use('OpenILS.data'); this.OpenILS = {}; 
		obj.OpenILS.data = new OpenILS.data(); obj.OpenILS.data.init({'via':'stash'});

		JSAN.use('util.list'); obj.list = new util.list('patron_list');
		function getString(s) { return obj.OpenILS.data.entities[s]; }

		JSAN.use('patron.util');
		var columns = patron.util.columns(
			{
			}
		);
		obj.list.init(
			{
				'columns' : columns,
				'map_row_to_column' : patron.util.std_map_row_to_column(),
				'retrieve_row' : function(params) {
					var id = params.retrieve_id;
					var patron = patron.util.retrieve_au_via_id( obj.session, id );

					var row = params.row;
					if (typeof row.my == 'undefined') row.my = {};
					row.my.au = patron;

					return row;
				}
			}
		);
		JSAN.use('util.controller'); obj.controller = new util.controller();
		obj.controller.init(
			{
				control_map : {
					'cmd_broken' : [
						['command'],
						function() { alert('Not Yet Implemented'); }
					],
				}
			}
		);

		if (obj.query) obj.search(obj.query);
	},

	'search' : function(query) {
		var search_hash = {};
		for (var i in query) {
			switch( i ) {
				case 'phone': case 'ident': 
				
					search_hash[ i ] = {};
					search_hash[ i ].value = query[i];
					search_hash[i].group = 2; 
				break;

				case 'street1': case 'street2': case 'city': case 'state': case 'post_code': 
				
					search_hash[ i ] = {};
					search_hash[ i ].value = query[i];
					search_hash[i].group = 1; 
				break;

				case 'family_name': case 'first_given_name': case 'second_given_name': case 'email':

					search_hash[ i ] = {};
					search_hash[ i ].value = query[i];
					search_hash[i].group = 0; 
				break;
			}
		}
		try {
			var results = this.network.request(
				api.fm_au_ids_retrieve_via_hash.app,
				api.fm_au_ids_retrieve_via_hash.method,
				[ this.session, search_hash ]
			);
			for (var i = 0; i < results.length; i++) {
				this.list.append( { 'retrieve_id' : results[i], 'row' : {} } );
			}
		} catch(E) {
			this.error.sdump('D_ERROR','patron.search_result.search: ' + js2JSON(E));
		}
	}

}

dump('exiting patron/search_result.js\n');
