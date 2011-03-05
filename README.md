# Area 51

You won't find [E.T.](http://www.youtube.com/watch?v=-uvw1wQZ5ZQ)
or [Alf](http://www.youtube.com/watch?v=J7g3FoMaGF0) here.  What you
will find is a gem that tries to make the act of defining restricted
and unrestricted areas of your web app a little easier.

The [RDocs](http://rubydoc.info/gems/area_51) are available
if you need them.

## Why?

There are already a lot of gems out there that provide authorization
capabilities, but they all (at least the ones I've seen) revolve around
model classes.  I had a need to authorize users for certain _paths_, not
models.  So, I did what any Rubyist would do when I couldn't find one
that existed.  I scratched my own itch and **Area 51** was born.

## Usage

    class ApplicationController < ActionController::Base
      area_51 do
        authorization_trigger("current_user.active?", :unrestricted) do
          restricted_area "^/memers_only"
          unrestricted_area "^/$"
        end
      end
    end

That's pretty much all there is to it.  The methods you should be
concerned with are `authorization_trigger`, `restricted_area`, and
`unrestricted_area`.

<a id="authorization_trigger" />

### `authorization_trigger`

Defines a trigger condition that when met, will cause authorization to be performed.

The trigger can be either a `String`, `lambda`, or `Proc`. If a `String`, it will
be `eval`'d, if a `lambda` or `Proc`, it will be called, and anything else will
be returned as-is. If the result does not return an explicit `true`, authorization will not be performed.

The `default_access` parameter, if provided, must be one of `:restricted` or `:unrestricted`. The
default is `:restricted`. This specifies what type of access the undefined areas will have. For example:

    authorization_trigger("current_user.active?", :unrestricted) do
      restricted_area "^/memers_only"
      unrestricted_area "^/$"
    end

In this example, if a user tries to access a path that isn't defined above, they will be
granted access due to the `:unrestricted` parameter.

### `restricted_area` and `unrestricted_area`

These methods tie a path to an authorization trigger.  It must be called within an
[`authorization`](#authorization_trigger) block:

    authorization_trigger("current_user.top_secret_clearance?") do
      restricted_area %r{^/top/secret/path}
      unrestricted_area %r{^/all_eyes}
    end

The method argument can be either a `String` or a `Regexp`. If a `String`, it will be converted to a `Regexp`.

## The End
