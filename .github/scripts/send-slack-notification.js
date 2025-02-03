const axios = require('axios');

async function sendSlackNotification(buildResult, prTitle, prUser, repo, runId,
    prNumber) {
  const safePrTitle = sanitizeInput(prTitle);
  const workflowURL = `https://github.com/${repo}/actions/runs/${runId}`;
  const prURL = `https://github.com/${repo}/pull/${prNumber}`;
  const message = `*Gradle build failed!*❌\nPR: "<${prURL}|${safePrTitle}>" by @${prUser}\nWorkflow URL: <${workflowURL}>`;
  const fallbackText = `Gradle build failed! PR: "${safePrTitle}" by @${prUser}`;

  if (buildResult === 'failure') {
    return axios.post(process.env.SLACK_WEBHOOK_URL, {
      text: fallbackText, blocks: [{
        type: "section", text: {
          type: "mrkdwn", text: message,
        },
      },], attachments: [{
        color: "#FF0000", fallback: fallbackText,
      },], username: 'GitHub Actions', icon_emoji: ':warning:',
    });
  }
}

const [buildResult, prTitle, prUser, repo, runId, prNumber] = process.argv.slice(
    2);
sendSlackNotification(buildResult, prTitle, prUser, repo, runId, prNumber)
.then(() => {
  console.log('Slack notification sent successfully!');
})
.catch((error) => {
  console.error(`Error sending Slack notification: ${error.message}!`);
});

function sanitizeInput(input) {
  if (typeof input !== 'string') {
    return '';
  }
  return input.replace(/[\r\n\t\f\b\v]/g, '').trim();
}
