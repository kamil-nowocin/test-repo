async function postComment(
  github,
  context,
  core,
  { task, regexPattern, passMessage, failMessage, buildResult }
) {
  const { owner, repo } = context.repo;
  const issue_number = context.issue.number || context.payload.pull_request?.number;
  const run_number = context.runNumber;
  const run_id = context.runId;
  const serverUrl = process.env.GITHUB_SERVER_URL || "https://github.com";
  const runUrl = `${serverUrl}/${owner}/${repo}/actions/runs/${run_id}`;
  let isFailed = false;

  switch (task) {
    case "validate-pr-title": {
      const title = context.payload.pull_request?.title || "";
      const regex = new RegExp(regexPattern);
      if (!regex.test(title)) {
        isFailed = true;
      }
      break;
    }

    case "build-result": {
      if (buildResult?.toLowerCase() !== "success") {
        isFailed = true;
      }
      break;
    }

    default:
      break;
  }

  const message = isFailed ? failMessage : passMessage;
  const finalBody = message
    .replace("{run_number}", run_number)
    .replace("{run_url}", runUrl);

  if (finalBody && issue_number) {
    await github.rest.issues.createComment({
      owner,
      repo,
      issue_number,
      body: finalBody,
    });
  }

  if (isFailed) {
    core.setFailed(`Task "${task}" failed its condition.`);
  }
}

module.exports = postComment;
