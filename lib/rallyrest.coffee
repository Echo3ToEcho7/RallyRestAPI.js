restler    = require "restler"
Futures    = require "futures"
Uri        = require "URIjs"
RallyQuery = require "./rally_query"
http       = require "http"

class RallyRest
	constructor: (opts) ->
		@opts = {}
		@opts.username         = opts.username       or ""
		@opts.password         = opts.password       or ""
		@opts.server           = opts.server         or "rally1.rallydev.com"
		@opts.version          = opts.version        or "1.36"
		@opts.project          = opts.project        or ""
		@opts.workspace        = opts.workspace      or ""
		@opts.pagesize         = opts.pagesize       or 200
		@opts.start            = opts.start          or 1
		@opts.projectScopeUp   = opts.projectScopeUp or false
		@opts.projectScopeDown = opts.projectScopeDown

		@opts.projectScopeDown ?= true

		@_buildComplete  = false
		@_artifactTypes  = {}

	_applyOptionsToQuery: (query) ->
		query
			.immutable()
			.projectScopeUp(@opts.projectScopeUp)
			.projectScopeDown(@opts.projectScopeDown)
			.project(@opts.project if /project\/\d*/.test(@opts.project))
			.workspace(@opts.workspace if /workspace\/\d*/.test(@opts.workspace))
			.start(@opts.start)
			.pagesize(@opts.pagesize)

	_buildQueryUri: (query) ->
		query = @_applyOptionsToQuery(query)

		o = query.toJSON()

		type = o.type.toLowerCase()
		delete o.query.project   if (type is "project") or (type is "workspace")
		delete o.query.workspace if type is "workspace"

		uri = new Uri("")

		uri.protocol("https")
			.hostname(@opts.server)
			.path("/slm/webservice/#{@opts.version}/#{o.type}.js")
			.query(o.query) + ""

	_sendGet: (uri) ->
		f = Futures.future()

		restler.get(uri, {
			username: @opts.username,
			password: @opts.password,
			headers: {
				Accept: "application/json"
			}
		}).on("complete", (data) -> f.fulfill(JSON.parse("#{data}")) )

		f

	_sendPost: (uri, data) ->
		f = Futures.future()

		restler.postJson(uri, data, {
			username: @opts.username,
			password: @opts.password,
			headers: {
				Accept: "application/json"
			}
		}).on("complete", (data) -> f.fulfill(JSON.parse("#{data}")) )

		f


	build: () ->
		f = Futures.future()

		findByName = (type, name, test) =>
			fw = Futures.future()
			
			if name is ""
				fw.fulfill(name)
				return fw

			if test.test(name)
				fw.fulfill(name)
				return fw

			q = (new RallyQuery()).type(type).fetch(["ObjectID"]).query("(Name = \"#{name}\")")

			@_sendGet(@_buildQueryUri(q)).when((data) =>
				fw.fulfill(data.QueryResult.Results[0])
			)

			fw

		findByName("Workspace", @opts.workspace, /workspace\/\d*/).when((ws) =>
			@opts.workspace = "/workspace/#{ws.ObjectID}" if ws?.ObjectID?
			findByName("Project", @opts.project, /project\/\d*/).when((p) =>
				@opts.project = "/project/#{p.ObjectID}" if p?.ObjectID?
				f.fulfill(ws, p)
			)
		)

		f

	typedefs: () ->
		f = Futures.future()

		q = (new RallyQuery())
			.type("TypeDefinition")
			.fetch(["Attributes", "DisplayName", "ElementName", "Name"])
			.fetch(["AtributeType", "Custom", "Hidden",  "Required"])

		uri = @_buildQueryUri(q.type("TypeDefinition"))

		@_sendGet(uri).when( (data) =>
			results = data.QueryResult.Results

			for res in results
				@_artifactTypes[res.ElementName] = {}
				@_artifactTypes[res.ElementName]._fields = (attr.ElementName for attr in res.Attributes)

			f.fulfill()
		)

		f

	find: (query) ->
		@_sendGet(@_buildQueryUri(query))

	findAll: (query) ->
		f = Futures.future()

		allResults  = []
		allErrors   = []
		allWarnings = []

		processNext = (query) =>
			q = query.mutable().start(query._start + query._pagesize)

			@_sendGet(@_buildQueryUri(q)).when((results) =>
				qr = results.QueryResult

				allResults  = allResults.concat(qr.Results)   if qr.Results.length > 0
				allErrors   = allErrors.concat(qr.Errors)     if qr.Errors.length > 0
				allWarnings = allWarnings.concat(qr.Warnings) if qr.Warnings.length > 0

				if qr.TotalResultCount >= qr.StartIndex + qr.Results.length
					processNext(q)
				else
					qr.Results    = allResults
					qr.Warnings   = allWarnings
					qr.Errors     = allErrors
					qr.StartIndex = 1

					f.fulfill({QueryResult: qr})
			)

		start = 1
		pagesize = 200

		processNext(query.mutable().start(start - pagesize).pagesize(pagesize))

		f

	_buildObjUri: (type, id) ->
		uri = new Uri("")

		uri.protocol("https")
			.hostname(@opts.server)
			.path("/slm/webservice/#{@opts.version}/#{type}/#{id}.js") + ""

	create: (type, obj) ->
		@_sendPost(@_buildObjUri(type, "create"), obj)

	read: (type, oid) ->
		@_sendGet(@_buildObjUri(type, oid))

	update: (ref, obj) ->
		@_sendPost(ref, obj)

	del: (ref) ->
		f = Futures.future()

		restler.del(ref, {
			username: @opts.username,
			password: @opts.password
		}).on("complete", () -> f.fulfill())

		f
