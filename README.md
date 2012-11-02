Node.js Wrapper for Rally's WSAPI
=================================

Usage
=====

{RallyRest, RallyQuery} = require "RallyRestAPI.js"

rally = new RallyRest({
  server: "rally1.rallydev.com",
  username: "cobrien@rallydev.com",
  password: "s3cret!",
  workspace: "Acme",
  project: "Online Store"
})

rally.build().when(() ->
  rally.find((new RallyQuery()).type("Artifact")).when((results) ->
    console.log(results)
  )
)
