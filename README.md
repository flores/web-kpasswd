# web-kpasswd

A very simple app to change your Kerberos password via a Sinatra frontend to kpasswd.

run it like $ ruby web-kpasswd.rb

## Oh snap...

* This script does not encrypt the password and instead just talks to localhost.  Therefore, you will need to configure krb5/etc so that a system call to kpasswd works.
* This sinatra app is not locked down!  At the least it needs to live behind a mod_krb'd Apache or some other webserver that will do Kerberos authentication to the app.  See the sample directory for a sample Apache conf.
* This app should run over HTTPS!  See the sample directory for a sample Apache conf to redirect all traffic to HTTPS.
