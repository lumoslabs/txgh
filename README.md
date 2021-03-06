Transifex Txgh (Lumos Labs fork)
====

[![Build Status](https://travis-ci.org/lumoslabs/txgh.svg?branch=master)](https://travis-ci.org/lumoslabs/txgh)

Txgh, a mashup of "Transifex" and "Github", is a lightweight server that connects Transifex and Github via webhooks. It enables automatic translation of new content pushed to your Github repository, and supports single-resource as well as branch-based git workflows.


How Does it Work?
---

1. When a source file is pushed to Github, the Txgh service will update the corresponding Transifex resource with the contents of the new file. Configuration options exist to process only certain branches and tags.

2. When a resource in Transifex reaches 100% translated, the Txgh service will download the translations and commit them to the target repository. Configuration options exist to protect certain branches or tags from automatic commits.

<br>
For the more visually inclined:
![Txgh Use Cases](https://www.gliffy.com/go/publish/image/9483799/L.png)
<br>
<br>

Supported Workflows
---

Use the following table to determine if Txgh will work for your git and translation workflow:

|Workflow|Comments|
|:--------|:----------|
|**Basic**<br>* You maintain one master version of your translations<br>* Translations may not be under source control<br>* New content is translated before each release and does not change until the next release|This is the default. Txgh <br> can also be configured to only<br> listen for changes that happen<br> on a certain branch or tag.|
|**Multi-branch**<br>* Your team is small or everyone works from the same branch<br>* Translations should change when code changes|You might want to consider <br>multi-branch with diffs (below)<br> since your translators may see<br> a number of duplicate strings<br> in Transifex using this workflow.|
|**Multi-branch with Diffs**<br>* Your team uses git branches for feature development<br>* Translations should change when code changes|This is the recommended workflow<br> if you'd like to manage translations<br> in an agile way, i.e. "continuous<br> translation." Only new and changed<br> phrases are uploaded to Transifex.|

Getting Started
---

Txgh supports a significant number of configuration options, and you'll need to familiarize yourself with them to ensure you're setting Txgh up to serve your particular needs. That said, we've whipped up a couple of templates with sensible defaults to get you started more quickly. If you're thinking about deploying with Docker, take a look at our [Docker template](https://github.com/lumoslabs/txgh-docker-template). If you want more flexibility (i.e. the ability to add custom middleware, etc), take a look at our [ruby template](https://github.com/lumoslabs/txgh-ruby-template). The rest of the setup steps below assume you're using one of these templates.

1. Open a terminal window and run `./bin/configure`. Follow the instructions to add a new project to `config.yml`. You'll need to have some version of Ruby installed on your system to run the configuration script. Refer to the section marked "Configuring Txgh" below for a detailed explanation of each option.

2. Create a file in your repository named `.tx/config` and add appropriate tx config. Txgh uses this information to know which files should be watched for changes. Refer to the section marked "Tx Config" below for more information.

3. If you've configured Txgh to upload diffs, visit your project's page in Transifex and upload each of the files described in your tx config. Use Transifex's categories feature to add a category of `branch:heads/master` to each resource. These full resources will provide the base set of translations for your project.

4. At this point, you're ready to deploy Txgh. There are a number of ways to do this, including using a host like AWS or Heroku. It's important your Txgh instance is publicly accessible over the Internet, because the next few steps involve setting up webhooks, which rely on being able to reach it.

5.
* Github: Visit the settings page for your Github repository, click on "Webhooks and Services," then click the "Add webhook" button. Under payload URL, fill in the URL of your publicly accessible Txgh instance and the path to the Github hook. For example, `http://mytxgh.herokuapp.com/hooks/github`. Fill in the "Secret" field with the Github `webhook_secret` generated for you in `config.yml`. Make sure to enable the "push" event, and also the "delete" event if you have configured Txgh to automatically delete resources. When the webhook is first created, Github will send your Txgh instance a "ping" test event. Your Txgh instance should respond with a 200 OK.
* Gitlab: Visit the webhooks settings page for your Gitlab repository. Under payload URL, fill in the URL of your publicly accessible Txgh instance and the path to the Gitlab hook. For example, `http://mytxgh.herokuapp.com/hooks/gitlab`. Fill in the "Secret" field with the Gitlab `webhook_secret` generated for you in `config.yml`. Make sure to enable the "Push events" trigger, it also includes the "delete" event if you have configured Txgh to automatically delete resources. When the webhook is first created, Gitlab will send your Txgh instance a test event. Your Txgh instance should respond with a 200 OK.

6. Visit the Manage -> Edit Project page for your Transifex project. Scroll down to the "Features" header and look for the "Web Hook URL" field. Fill it in with the URL of your publicly accessible Txgh instance and the path to the Transifex hook. For example, `http://mytxgh.herokuapp.com/hooks/transifex`. Fill in the "Secret Key" field with the Transifex `webhook_secret` generated for you in `config.yml`.

7. Congratulations, you now have a running, fully configured Txgh instance! Note that the configuration script you ran in step 1 automatically configured Txgh to process all branches, so you should be able to create a test branch, modify some translations, and push your changes. Txgh is configured correctly if a new resource appears in Transifex with the new branch name attached.

Available Endpoints
---

Txgh exposes the following endpoints:

* **`POST /hooks/github`**: Receives and processes Github webhook requests. Request body is expected to be a Github webhook payload in JSON format. Uploads any modified translatable content to Transifex. This endpoint is protected by shared secret signature authorization.

* **`POST /hooks/gitlab`**: Receives and processes Gitlab webhook requests. Request body is expected to be a Gitlab webhook payload in JSON format. Uploads any modified translatable content to Transifex. This endpoint is protected by shared secret authorization.

* **`POST /hooks/transifex`**: Receives and processes Transifex webhook requests. Request body is expected to be a Transifex webhook payload in JSON format. Commits translations back to the Github repository. This endpoint is protected by shared secret signature authorization.

* **`PATCH /push?project_slug=[slug]&branch=[branch]`**: Causes translatable content from Github to be pushed to Transifex. This endpoint is designed to emulate receiving a Github webhook, but doesn't require the usual massive Github webhook payload. Currently this endpoint is not protected (but it should be).

* **`PATCH /pull?project_slug=[slug]&branch=[branch]`**: Causes translations from Transifex to be committed to Github. This endpoint is designed to emulate receiving a Transifex webhook, but doesn't require the usual Transifex webhook payload. Currently this endpoint is not protected (but it should be).

* **`GET /config?project_slug=[slug]&branch=[branch]`**: Returns the tx config in JSON format for the given project and branch.

* **`GET /health_check`**: Simply returns an HTTP 200 OK.

Configuring Txgh
---

Config is written in the YAML markup language and is comprised of three sections, one for Github options, one for Gitlab options and one for Transifex options:

```yaml
github:
  repos:
    organization/repo:
      api_username: github username
      api_token: abcdefghijklmnopqrstuvwxyz github api token
      push_source_to: transifex project slug
      branch: branch to watch for changes, or "all" to watch all of them
      tag: tag to watch for changes, or "all" to watch all of them
      webhook_secret: 123abcdef456ghi github webhook secret
      diff_point: branch to diff against (usually master)
gitlab:
  repos:
    idanci/txgl-test:
      api_token: gitlab api token
      push_source_to: txgl-test
      branch: all
      webhook_secret: '123456789' gitlab webhook secret
      diff_point: heads/master
      commit_message: "[skip ci] Updating %{language} translations in %{file_name}"
transifex:
  projects:
    project-slug:
      tx_config: map of transifex resources to file paths
      api_username: transifex username
      api_password: transifex password (transifex doesn't support token-based auth)
      push_translations_to: organization/repo
      protected_branches: branches that should not receive automatic commits
      webhook_secret: 123abcdef456ghi transifex webhook secret
      auto_delete_resources: 'true' to delete resource when branch is deleted
```

### Github Configuration

* **`api_username`**: Your Github account username. You might want to create a new dev Github account for Txgh to use instead of providing someone's actual credentials here. Keep in mind that the username you specify must have access to the repository in question, or Github will reject all Txgh's API requests.

* **`api_token`**: A valid Github access token. The token should be generated by the username specified by `api_username`. In Github, visit your account settings and generate a personal access token. Give the token all the "repo" permissions.

* **`push_source_to`**: The slug of the Transifex project you want to push new translatable content to. The slug is basically the name of the project, but with URL-unfriendly characters removed. You can find the slug of your project by inspecting the URL on any Transifex project page.

* **`branch`**: The Github branch to watch for new translatable content. If you want Txgh to watch all branches, use the special value "all". By default, branch is `master`.

* **`tag`**: The Github tag to watch for new translatable content. If you want Txgh to watch all tags, use the special value "all".

* **`webhook_secret`**: A user-defined string that Github will use to sign webhook requests. If present, Txgh will use this value to verify the authenticity of these webhook requests and reject those that are improperly signed. Make sure you use this same value when configuring the webhook in the Github UI.

* **`diff_point`**: The branch to compare against when submitting new translatable content to Transifex, usually `master`. Set this option to enable diffing. If not set, Txgh will upload changed files in their entirety.

### Gitlab Configuration

* **`api_token`**: A valid Gitlab access token. The token should be generated by the user who has access to the relevant repo. In Gitlab, visit your account settings and generate a personal access token with all the read/write permissions https://gitlab.com/profile/personal_access_tokens

* **`push_source_to`**: The slug of the Transifex project you want to push new translatable content to. The slug is basically the name of the project, but with URL-unfriendly characters removed. You can find the slug of your project by inspecting the URL on any Transifex project page.

* **`branch`**: The Gitlab branch to watch for new translatable content. If you want Txgh to watch all branches, use the special value "all". By default, branch is `master`.

* **`webhook_secret`**: A user-defined string that Gitlab will send in the headers for webhook requests. If present, Txgh will use this value to verify the authenticity of these webhook requests and reject those that are missmatching. Make sure you use this same value when configuring the webhook in the Gitlab UI.

* **`diff_point`**: The branch to compare against when submitting new translatable content to Transifex, usually `master`. Set this option to enable diffing. If not set, Txgh will upload changed files in their entirety.

### Transifex Configuration

* **`tx_config`**: Configuration specifying which files to watch for changes. See the section labeled "Tx Config" below for more information.

* **`api_username`**: Your Transifex account username. You might want to create a new dev Transifex account for Txgh to use instead of providing someone's actual credentials here. Keep in mind that the username you specify must have access to the project in question, or Transifex will reject all Txgh's API requests.

* **`api_password`**: The Transifex account password associated with `api_username`. Transifex does not support token-based authentication or OAuth.

* **`push_translations_to`**: The Github repository to commit completed translations to. If configured to process a branch or branches, Txgh will commit translations back to the branch they came from.

* **`protected_branches`**: A comma-separated list of branches Txgh should never make automatic commits on. It can be useful to blacklist certain branches so as not to disrupt a release cycle or surprise your QA team.

* **`webhook_secret`**: A user-defined string that Transifex will use to sign webhook requests. If present, Txgh will use this value to verify the authenticity of these webhook requests and reject those that are improperly signed. Make sure to use this same value when configuring the webhook in the Transifex UI.

* **`auto_delete_resources`**: If set to "true", Txgh will automatically delete Transifex resources when the corresponding branch is deleted from git.

### Loading Config

Txgh supports two different ways of accessing configuration, raw text and a file path. In both cases, config is passed via the `TXGH_CONFIG` environment variable. Prefix the raw text or file path with the appropriate scheme, `raw://` or `file://`, to indicate which strategy Txgh should use.

#### Raw Config

Passing raw config to Txgh can be done like this:

```bash
export TXGH_CONFIG="raw://big_yaml_string_here"
```

When Txgh starts up, it will use the YAML payload that starts after `raw://`.

#### File Config

It might make more sense to store all your config in a file. Pass the path to Txgh like this:

```bash
export TXGH_CONFIG="file://path/to/config.yml"
```

When Txgh runs, it will read and parse the file at the path that comes after `file://`.

Of course, in both the file and the raw cases, environment variables can be specified via `export` or inline when starting Txgh. See the "Running Txgh" section below for more information.

Tx Config
---

In addition to the YAML configuration described above, Txgh needs to know which files to watch for changes. Txgh uses the same [ini-style config format](http://docs.transifex.com/client/config/#txconfig) as the Transifex CLI client, meaning you can simply point Txgh at this existing config and things will Just Work™. If you don't already have the CLI client configured, then keep reading.

You'll probably have to do some research to find out which formats Transifex supports in order to put together your tx config. You'll also need to know which files contain translatable content. Once you have all this information, constructing your tx config should be fairly straightforward.

### Format

By way of example, the tx config for a basic Rails app might look like this:

```ini
[main]
host = https://www.transifex.com
lang_map =

# Create one such section per file/resource
[myproject.enyml]
file_filter = config/locales/<lang>.yml
source_file = config/locales/en.yml
source_lang = en
type = YML
```

For every file you'd like Txgh to watch for changes, add another section to the config. The section header enclosed in square brackets is comprised of the project slug, a period, and the resource slug. The project slug can be found by inspecting the URL on Transifex project pages, while the resource slug is something you can make up. Keep in mind that resource slugs in the same project must be unique. Try to choose a name that makes it easy to identify the resource at-a-glance later.

Here's a description of each of the fields:

* **`file_filter`**: I'm not sure why this field is called `file_filter` since a more appropriate name would be "translation\_file" or "translation\_path\_template". Basically this field is a template that indicates where translations should be saved. The `<lang>` part functions as a placeholder and gets swapped out for a language code. The Spanish translation file for example would be written to config/locales/es.yml.

* **`source_file`**: The file to watch for changes.

* **`source_lang`**: The language the strings inside the `source_file` are written in.

* **`type`**: The format the strings in both the `source_file` and `file_filter` are stored in. This format must be supported by Transifex. For a full list of supported i18n types, see the [Transifex documentation](http://docs.transifex.com/formats/). Rails stores translations in the YAML file format. For a JavaScript project you might store translations in JSON and choose the KEYVALUEJSON i18n type. For Android XML, the ANDROID i18n type, etc.

### Loading Tx Config

Tx config is loaded in a similar fashion to Txgh config. There are three supported schemes, `raw`, `file`, and `git`. Both `raw` and `file` behave the same as their Txgh config counterparts, but the `git` scheme is different. It allows tx config to be downloaded dynamically from a git repository instead of read from a static string or file. This means you can store tx config in your git repository itself, where it can be versioned and changed on a per-branch basis. There are several benefits to this. First, any time you add a file to the tx config in a feature branch, that file will be identified and uploaded for that branch only without any additional configuration changes. Second, it places the responsibility of maintaining translated resources with the engineers working in the repo itself rather than on the engineers maintaining your translation infrastructure.

Loading tx config from git is straightforward. Use the `git://` scheme followed by the path to the config file inside the repository, eg. `git://.tx/config`.

For example, the Transifex section of your Txgh config might look like this:

```yaml
transifex:
  projects:
    project-slug:
      tx_config: git://.tx/config
      ...
```

Every time a request is made, Txgh will download `.tx/config` from the given branch and use it to identify changed files.

Running Txgh
---

Txgh is distributed as a [Docker image](https://quay.io/repository/lumoslabs/txgh) and as a [Rubygem](https://rubygems.org/gems/txgh). You can choose to run it via Docker, install and run it as a Rubygem, or run it straight from a local clone of this repository.

### With Docker

Using Docker to run Txgh is pretty straightforward (keep in mind you'll need to have the Docker server set up wherever you want to run Txgh).

NOTE: You might consider using this [Docker template](https://github.com/lumoslabs/txgh-docker-template) instead of following the instructions below. The template contains all the files and scripts you need to get up and running quickly.

First, pull the Txgh image:

```bash
docker pull quay.io/lumoslabs/txgh:latest
```

Run the image in a new container:

```bash
docker run
  -p 9292:9292
  -e "TXGH_CONFIG=raw://$(cat path/to/config.yml)"
  quay.io/lumoslabs/txgh:latest
```

At this point, Txgh should be up and running. To test it, try hitting the `health_check` endpoint. You should get a 200 response:

```bash
curl -v localhost:9292/health_check
....
< HTTP/1.1 200 OK
```

Note that Txgh might not be available on localhost depending on how your Docker client is configured. On a Mac with [docker-machine](https://docs.docker.com/machine/) for instance, you might try this instead:

```bash
curl -v 192.168.99.100:9292/health_check
```

(Where 192.168.99.100 is the IP of your docker machine instance).

### From Rubygems

Docker is by far the easiest way to run Txgh, but a close runner-up is via Rubygems. You'll need to have at least Ruby 2.1 installed as well as the [bundler gem](http://bundler.io/). Installing ruby and bundler are outside the scope of this README, but I'd suggest using a ruby installer like [rbenv](https://github.com/rbenv/rbenv) or [rvm](https://rvm.io/) to get the job done. Once ruby is installed, executing `gem install bundler` should be enough to install the bundler gem.

NOTE: You might consider using this [ruby template](https://github.com/lumoslabs/txgh-ruby-template) instead of following the instructions below. The template contains all the files and scripts you need to get up and running quickly.

1. Create a new directory for your Txgh instance.

2. Inside the new directory, create a file named `Gemfile`. This file is a manifest of  all your ruby dependencies.

3. Inside `Gemfile`, add the following lines:

  ```ruby
  source 'http://rubygems.org'
  gem 'txgh', '~> 1.0'
  ```
  When bundler parses this file, it will know to fetch dependencies from rubygems.org, the most popular and ubiquitous gem host. It will also know to fetch and install the txgh gem.
4. Create another file next to `Gemfile` named `config.ru`. This file describes how to run the Txgh server, including where to mount the various endpoints.
5. Inside `config.ru` add the following lines:

  ```ruby
  require 'txgh'

  map '/' do
    use Txgh::Application
    use Txgh::Triggers
    run Sinatra::Base
  end

  map '/hooks' do
    use Txgh::Hooks
    run Sinatra::Base
  end
  ```

  Where each endpoint is mounted is entirely configurable inside this file, as is any additional middleware or your own custom endpoints you might want to add. Txgh is built on the [Rack](http://rack.github.io/) webserver stack, meaning the wide world of Rack is available to you inside this file. The `map`, `use`, and `run` methods are part of Rack's builder syntax.

6. Run `bundle install` to install gem dependencies.

7. Run `TXGH_CONFIG=file://path/to/config.yml bundle exec rackup`. The Txgh instance should start running in the foreground.

8. Test your Txgh instance by hitting the `health_check` endpoint as described above in the "With Docker" section, i.e. `curl -v localhost:9292/health_check`. You should get an HTTP 200 response.

### Local Clone

Running Txgh from a local copy of the source code requires almost the same setup as running it from Rubygems. Notably however the `config.ru` file has already been written for you.

Refer to the "From Rubygems" section above to get ruby and bundler installed before continuing.

1. Clone Txgh locally:

  ```bash
  git clone git@github.com:lumoslabs/txgh.git
  ```

2. Change directory into the newly cloned repo (`cd txgh`) and run `bundle install` to install gem dependencies.
3. Run `TXGH_CONFIG=file://path/to/config.yml bundle exec rackup`. The Txgh instance should start running in the foreground.

4. Test your Txgh instance by hitting the `health_check` endpoint as described above in the "With Docker" section, i.e. `curl -v localhost:9292/health_check`. You should get an HTTP 200 response.

Running Tests
---

Txgh uses the popular RSpec test framework and has a comprehensive set of unit and integration tests. To run the full test suite, run `bundle exec rake spec:full`, or alternatively `FULL_SPEC=true bundle exec rspec`. To run only the unit tests (which is faster), run `bundle exec rspec`.

Requirements
---

Txgh requires an Internet connection to run, since its primary function is to connect two web services via webhooks and API calls. Other than that, it does not have any other external requirements like a database or cache.

Compatibility
---

Txgh was developed with Ruby 2.1.6, but is probably compatible with all versions between 2.0 and 2.3, and maybe even 1.9. Your mileage may vary when running on older versions.

Authors
---

This repository is a fork of Transifex's [original](https://github.com/transifex/txgh) and is maintained by [Cameron Dutro](https://github.com/camertron) from Lumos Labs.

License
---

Licensed under the Apache License, Version 2.0. See the LICENSE file included in this repository for the full text.
