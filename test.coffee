{RallyRest, RallyQuery} = require "./"

rally = new RallyRest({
	server: "demo01.rallydev.com",
	username: "cobrien@rallydev.com",
	password: "Just4Rally",
	workspace: "Acme",
	project: "Online Store"
})

rally.build().when(() ->
	rally.find((new RallyQuery()).type("Artifact")).when((results) ->
		console.log(results)
	)
)

