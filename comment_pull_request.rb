require 'octokit'

# Extract the Pull Request ID from passed argument
id=ARGV[0]
REPO_NAME = ARGV[1]
PREVIEW_URL = ARGV[2]

# Initialise the Octokit client with the Github access token for the user-bot account
client = Octokit::Client.new :access_token => ENV['GOOEY_SPLASHSITE_TOKEN']

# Send the comment using add_comment(<repo_name>, <PR#id>, <comment_string>)
client.add_comment(REPO_NAME, id, "Preview is available on #{PREVIEW_URL}#{id} :rocket:")

