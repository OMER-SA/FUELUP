const { GoogleAuth } = require('../functions/node_modules/google-auth-library');
const serviceAccount = require('../functions/serviceAccountKey.json');

async function main() {
  const auth = new GoogleAuth({
    credentials: serviceAccount,
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  });

  const client = await auth.getClient();
  const token = (await client.getAccessToken()).token;

  const url = `https://firestore.googleapis.com/v1/projects/${serviceAccount.project_id}/databases`;
  const response = await fetch(url, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  const body = await response.text();
  console.log(`HTTP ${response.status}`);
  console.log(body);
}

main().catch((error) => {
  console.error(`CHECK_FAILED: ${error.message}`);
  process.exit(1);
});
