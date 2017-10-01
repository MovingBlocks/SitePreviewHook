# hook.rb
require 'sinatra'
require 'json'

REPO_DIR = "/home/nihal/splashsite"
TRIGGER_COMMAND = "Let's preview this"
REPO_LINK = "git@github.com:MovingBlocks/movingblocks.github.com.git"
REPO_NAME = "MovingBlocks/movingblocks.github.com"
ROOT_DIR = "/home/nihal"
DEPLOY_PATH = "/var/www"
SUB_PATH = "/splashsite/pull"
PREVIEW_URL = "http://preview.terasology.net/splashsite/pull/"

set :bind, '0.0.0.0'

def push(json_body)
  puts "Push Event \n Updating the repository\n"
  system("sudo -E ./update_repo.sh #{REPO_LINK} #{REPO_DIR}")
end

def issue_comment(json_body)
  # Check for action key presence, break if not present
  present = json_body.has_key? "action"
  return if present == false
  action = json_body.fetch("action")
  return if !(action == "created" or action == "edited")

  # Check for issue->pull_request key presence, break if not present
  present = json_body.has_key? "issue"
  return if present == false
  present = json_body.fetch("issue").has_key? "pull_request"
  return if present == false

  # Extract the pull request html url
  pull_request_url = json_body.fetch("issue").fetch("pull_request").fetch("html_url")
  id = pull_request_url.split('/')[-1]
  puts "Issue Comment Event"
  puts "PR URL- #{pull_request_url}"

  # Find if comment -> body is present, break if not present
  present = json_body.has_key? "comment"
  return if present == false
  present = json_body.fetch("comment").has_key? "body"
  return if present == false
  
  # Extract commit id and user
  commit_id = json_body.fetch("comment").fetch("id")
  commit_user = json_body.fetch("comment").fetch("user").fetch("login")  
  puts "Comment by #{commit_user} with ID-#{commit_id}"

  # Extract the comment body
  comment_body = json_body.fetch("comment").fetch("body")
  puts "Comment body: #{comment_body}"

  # Check if comment contains trigger command
  if comment_body.include? TRIGGER_COMMAND
    puts "\nComment has trigger command. Sending for preview"

    system("sudo -E ./pull_request_preview.sh #{REPO_LINK} #{REPO_DIR} #{id} #{ROOT_DIR} #{DEPLOY_PATH} #{SUB_PATH} #{REPO_NAME} #{PREVIEW_URL} &")
  end
end

def verify_signature(payload_body)
  signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV['HOOK_TOKEN'], payload_body)
  if request.env['HTTP_X_HUB_SIGNATURE']
    return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
  else
    return halt 500, "No Signature sent"
  end
end


post '/payload' do
  
  request.body.rewind
  payload_body = request.body.read
  verify_signature(payload_body)
  
  github_event = request.env["HTTP_X_GITHUB_EVENT"]
  puts "\nGithub Event- #{github_event} \n" 

  # Extract JSON from request and parse it
  json_body = JSON.parse(payload_body)
  
  if (github_event == "push")
    puts push(json_body)  
  end

  if (github_event == "issue_comment")
    puts issue_comment(json_body)
  end  
end
