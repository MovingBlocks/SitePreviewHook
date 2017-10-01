# SitePreviewHook
A web hook for generating and serving site previews from Pull Requests.

## Objective:
To trigger a build for every PR to a static jekyll site and deploy it to a preview website. Each Pull Request can be built separately and made available on the website. The result should appear so-

![PullRequestComments](/PR.png)

## Built using:

- Ruby
- Gems: octokit, sinatra
- Shell scripts
- GitHub webhooks and API
- nginx

## How does it work?

The repository for the website is cloned and kept. Whenever the master branch on GitHub is updated or pushed to, the cloned repository is made to fetch all the new changes. Here is how it happens-

1. When a commit is pushed to the the repository, GitHub fires a POST request for the event- "push"
2. The ruby script which listens for all such requests actively, receives the POST and executes a shell script.
3. The shell script pulls the changes in the master branch of the cloned repository.

To Preview a Pull Request, a comment with the right phrase needs to be made. Here is the order in which things happen-

1. To trigger a build, one has to comment with "Let's preview this" on Pull Request in GitHub. 
2. This triggers the GitHub to fire a payload over through the webhook for the event- "issue_comment".
3. The ruby script which listens for all such requests actively, receives the POST, extracts the Pull Request number and executes a shell script.
5. The shell script fetches the Pull Request in another branch named after the Pull Request's number.
6. It then builds the jekyll site with something like `--baseurl="/splashsite/pull/<PR#>"`. This is done, because multiple Pull Requests are to be served at different paths.
7. The built site is then copied over to the respective directory for deployment, something like `/var/www/splashsite/pull/<PR#>/`.
8. The shell script in turn calls another ruby script to deliver a comment to the Pull Request in GitHub, saying that the build is complete and the preview is available, with the right link.

## Usage:

### Download

Download these files and move them to a folder-
1. [hook.rb](/hook.rb)- The main ruby script that runs in the background and listens for POST requests.
2. [update_repo.sh](/update_repo.sh)- The shell script to update the local cloned repository when a push is heard.
3. [pull_request_preview.sh](/pull_request_preview.sh)- The shell script to preview a pull request given its ID.
4. [comment_pull_request.sh](/comment_pull_request.sh)- The shell script to comment on the pull request with preview link.

Clone the GitHub repository for the static site in the same folder.

### GitHub Setup
Create a GitHub webhook for the static site repository.

- Set Payload URL to "http://preview.terasology.net:1234/payload"
- Set Content type to application/json
- Set Secret to a random 20 character string.
	> ruby -rsecurerandom -e 'puts SecureRandom.hex(20)
- Set the same random string as an environment variable on the server.
`export HOOK_TOKEN=your_token`
- Select relevant individual events ("push" and "issue_comment" here)
- Leave Active as check marked

### Create GitHub User-Bot
Github doesn't have bots. Fortunately, we can create a user account and make it function as a bot.

1. Create a new user account, in our case it is `gooey-splashsite`.
2. Go to Settings from the top right drop down menu and select Personal Access Token down at the bottom of the list.
3. Create a new access token with the relevant right (just `public_repo` here).
4. Copy the token and note it down (to be used in [comment_pull_request.sh](/comment_pull_request.sh) script). Note that you should not use the token directly in the token and it is best to use it as an environment variable. To create an environment variable do something like:
`export GOOEY_SPLASHSITE_TOKEN=your_token`

Read more about securing your webhook [here](https://developer.github.com/webhooks/securing/).


### Customize
Change the parameters in the `hook.rb` file as per your need:

The path to the cloned directory.  
- **REPO_DIR** = /home/nihal/splashsite 

The command that triggers the build to happen.  
- **TRIGGER_COMMAND** = "Let's preview this"

The link to the GitHub repository.  
- **REPO_LINK** = "git@github.com:MovingBlocks/movingblocks.github.com.git"

The Name of the Repository in user/repo format
- **REPO_NAME** = "MovingBlocks/movingblocks.github.com"

The root directory where script files and cloned GitHub repo is located.
- **ROOT_DIR** = "/home/nihal"

Base deploy path which is served.
- **DEPLOY_PATH** = "/var/www"

Sub path for the preview.
- **SUB_PATH** = "/splashsite/pull"

Preview URL without terminating PR number.
- **PREVIEW_URL** = "http://preview.terasology.net/splashsite/pull/"

Note: All directory paths should necessarily NOT have a "/" at the end.

### Configure nginx

Read more about setting up nginx server blocks [here](https://www.digitalocean.com/community/tutorials/how-to-set-up-nginx-server-blocks-virtual-hosts-on-ubuntu-16-04).

Create a new server configuration in `/etc/nginx/sites-enabled`. Let's call this [splashsite](/nginx-config). Copy the main contents from the default server block.
```
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/splashsite
```

Make the following changes:
```
server {
	listen 80;
	listen [::]:80;

	# Add index.php to the list if you are using PHP
	index index.html index.htm index.nginx-debian.html;

	server_name preview.terasology.net www.preview.terasology.net;

	location / {
		root /var/www/html;
		# First attempt to serve request as file, then
		# as directory, then fall back to displaying a 404.
		try_files $uri $uri/ =404;
	}

	location /splashsite {
		alias /var/www/splashsite/html;
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                try_files $uri $uri/ =404;
        }

	location ~ ^/splashsite/pull/(\d+) {
                alias /var/www;
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
		try_files $uri $uri/l $uri/index.html =404;
        }

}
```

Link the new created server block file to enable them.
```
sudo ln -s /etc/nginx/sites-available/splashsite /etc/nginx/sites-enabled/
```


### Execute

Execute the script to run by using this command-  
`nohup sudo -E ruby hook.rb -o 0.0.0.0 -p 1234 >>/home/nihal/hooklog.txt &`  
The 1234 should be the same as the port set in the GitHub webhook.  
The sudo -E preserves the Environment Variables of the user allowing you to access HOOK_TOKEN and other set token keys.

Commenting with "Let's preview this" or the changed `TRIGGER_COMMAND` should now serve the Pull Request at the preview website.

### Author

This script is written by [Nihal Singh](http://github.com/nihal111/).