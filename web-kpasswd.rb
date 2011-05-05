#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'rack'
require 'haml'
require 'base64'

# If the user has authenticated via Kerberos 5 on the frontend server, 
# this header is coming over
def authenticate()
	user_env = @env["Authorization"] || @env["HTTP_AUTHORIZATION"]
        if user_env
                user = Base64.decode64(user_env[6,user_env.length-6])[/\w+/]
		return user
        else
        	return nil
	end
end

set :environment, :production
set :bind, 'localhost'

get '/' do
	redirect '/changepw'
end

get '/unauthenticated' do
	haml :unauthenticated
end

get '/changepw' do
	@user=authenticate()
	unless @user
		redirect '/unauthenticated'
	end
	haml :changepw
end

post '/changepw' do
	@user=authenticate()
	unless @user
		redirect '/unauthenticated'
	end
	currentpass	= params["current"]
	newpass		= params["new"]
	newpass_sanity	= params["new_sanity"]

	# basic checks
	if newpass != newpass_sanity
		haml :passwords_do_not_match
	elsif newpass == currentpass
		haml :password_did_not_change
	# weak exploit prevention
	elsif ( currentpass.length || newpass.length ) > 64
		haml :password_too_long
	else
		require 'pty'    
		require 'expect'

		@error = ""

		# spawn a child process (fork)
		PTY.spawn("/usr/bin/kpasswd #{@user}") do |output, input, pid|
		   input.sync = true
   		   expect_verbose = false

   		   # kpasswd will return the realm name, so let's just regex 
		   # for the bit we care about.
   		   output.expect(/Password for #{@user}/) do
      			input.puts(currentpass)
   		   end

   		   output.expect('Enter new password: ') do
     			input.puts(newpass)
   		   end
   		   
		   output.expect('Enter it again: ') do
     			input.puts(newpass)
   		   end

		   # might not actually be an error.  We're returning the output
		   # success will be "Password changed"
       		   @error=output.read
		
		end
		# then we just display it on a page with a back button.
		haml :kpasswd_results
	end
end	
