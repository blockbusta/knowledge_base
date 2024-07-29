# SMTP

<aside>
✅ **Ruby ActionMailer settings explained:**
[https://guides.rubyonrails.org/action_mailer_basics.html#:~:text=and Log4r loggers.-,smtp_settings,-Allows detailed configuration](https://guides.rubyonrails.org/action_mailer_basics.html#:~:text=and%20Log4r%20loggers.-,smtp_settings,-Allows%20detailed%20configuration)

</aside>

### test mail from rails console

check SMTP settings in rails console:

```python
ActionMailer::Base.smtp_settings
```

send custom mail to any address:

```python
mailer = ActionMailer::Base.new

mailer.mail(from: 'info@webapp.me', to: 'your@mail.com', subject: 'testing 123', body: "hello world").deliver
```

if the response sent back is a green colored hash - all’s good

you can test custom smtp settings live in rail console, by re-configuring ActionMailer instance:

```python
ActionMailer::Base.smtp_settings = {:user_name=>"dadada",
 :password=>"lalala",
 :domain=>"webapp.me",
 :address=>"smtp.blablabla.com",
 :port=>"587",
 :authentication=>:plain,
 :enable_starttls_auto=>true}
```