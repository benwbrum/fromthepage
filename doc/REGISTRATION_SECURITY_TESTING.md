# Registration privilege-escalation regression test

Use these steps only in a local, staging, or other environment where you are
authorized to create test accounts. Use a new email address for each test.

## Reproduce the original vulnerability

These steps describe the behavior before the registration security fix.

1. Open `/users/sign_up` in a browser.
2. Fill in all required transcriber registration fields with a unique username
   and email address.
3. Open the browser developer tools and run this in the console:

   ```javascript
   const form = document.querySelector('form');
   form.insertAdjacentHTML(
     'beforeend',
     '<input type="hidden" name="user[owner]" value="1">' +
       '<input type="hidden" name="user[paid_date]" value="2099-12-31">'
   );
   ```

4. Submit the registration form.
5. Observe that the new account is sent to an owner dashboard rather than the
   transcriber watchlist.
6. In a Rails console, confirm the unauthorized values were persisted:

   ```ruby
   user = User.find_by!(email: 'the-test-email@example.com')
   user.owner
   user.paid_date
   ```

   On a vulnerable revision, `owner` is `true` and `paid_date` contains the
   attacker-selected date.

## Verify the fix

1. Open `/users/sign_up` and fill in all required fields with another unique
   username and email address.
2. Use the same developer-tools snippet above to inject `user[owner]` and
   `user[paid_date]` into the form.
3. Submit the form.
4. Confirm the new account is sent to the transcriber watchlist, not an owner
   dashboard.
5. In a Rails console, verify that the submitted privileged values were
   ignored:

   ```ruby
   user = User.find_by!(email: 'the-second-test-email@example.com')
   user.owner       # => false
   user.account_type # => nil
   user.paid_date   # => nil
   ```

## Verify legitimate trial registration

The security fix must not prevent the intended trial-owner flow.

1. Open `/users/new_trial` and fill in the required fields.
2. Before submitting, inject attacker-selected values in the developer-tools
   console:

   ```javascript
   const form = document.querySelector('form');
   form.insertAdjacentHTML(
     'beforeend',
     '<input type="hidden" name="user[owner]" value="0">' +
       '<input type="hidden" name="user[account_type]" value="Staff">' +
       '<input type="hidden" name="user[paid_date]" value="2099-12-31">'
   );
   ```

3. Submit the form and confirm the account reaches the trial-owner dashboard.
4. In a Rails console, verify that the server, rather than the submitted
   fields, selected the account properties:

   ```ruby
   user = User.find_by!(email: 'the-trial-test-email@example.com')
   user.owner        # => true
   user.account_type # => "Trial"
   user.paid_date    # approximately two weeks after registration
   ```

## Automated regression test

Run the request specs that submit the same malicious parameters directly:

```shell
bundle exec rspec spec/requests/registrations_controller_spec.rb
```
