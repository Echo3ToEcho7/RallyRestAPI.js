util = require "util"

class RallyQuery
	constructor: () ->
		@_fetch = []
		@_mutable = true

	mutable: () ->
		@_mutable = true
		@

	immutable: () ->
		@_mutable = false
		@

	type: (type) ->
		if @_mutable
			@_type = type
		else
			@_type ?= type

		@

	start: (val) ->
		if @_mutable
			@_start = val
		else
			@_start ?= val

		@

	pagesize: (val) ->
		if @mutable
			@_pagesize = val
		else
			@_pagesize ?= val

		@

	projectScopeUp: (val) ->
		if @_mutable
			@_projectScopeUp = val
		else
			@_projectScopeUp ?= val

		@

	projectScopeDown: (val) ->
		if @_mutable
			@_projectScopeDown = val
		else
			@_projectScopeDown ?= val

		@

	project: (val) ->
		if @_mutable
			@_project = val
		else
			@_project ?= val

		@

	workspace: (val) ->
		if @_mutable
			@_workspace = val
		else
			@_workspace ?= val

		@
	
	fetch: (val) ->
		if util.isArray(val)
			@_fetch = @_fetch.concat(val)
		else
			@_fetch.push(val)

		@

	query: (val) ->
		if @_mutable
			@_query = val
		else
			@_query ?= val

		@

	toJSON: () ->
		q = {}

		q.type = @_type if @_type?
		
		q.query                  = {}
		q.query.projectScopeUp   = @_projectScopeUp   if @_projectScopeUp?
		q.query.projectScopeDown = @_projectScopeDown if @_projectScopeDown?
		q.query.project          = @_project          if @_project?
		q.query.workspace        = @_workspace        if @_workspace?
		q.query.fetch            = @_fetch.join(",")  if @_fetch?
		q.query.start            = @_start            if @_start?
		q.query.pagesize         = @_pagesize         if @_pagesize?
		q.query.query            = @_query            if @_query

		q

module.exports = RallyQuery
