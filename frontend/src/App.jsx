import { useEffect, useState } from 'react'

const AUTH_CONFIG_PATH = '/auth-config.json'
const TOKEN_STORAGE_KEY = 'auth_tokens'
const CODE_VERIFIER_STORAGE_KEY = 'pkce_code_verifier'

async function fetchJson(url, accessToken) {
  return sendJson(url, { accessToken })
}

async function sendJson(url, { accessToken, method = 'GET', body } = {}) {
  const response = await fetch(url, {
    method,
    headers: {
      ...(accessToken ? { Authorization: `Bearer ${accessToken}` } : {}),
      ...(body !== undefined ? { 'Content-Type': 'application/json' } : {}),
    },
    ...(body !== undefined ? { body: JSON.stringify(body) } : {}),
  })
  const text = await response.text()

  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}: ${text.slice(0, 200)}`)
  }

  try {
    return JSON.parse(text)
  } catch {
    throw new Error(`${response.status} ${response.statusText}: ${text.slice(0, 200)}`)
  }
}

function encodeBase64Url(bytes) {
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/g, '')
}

function randomString(length = 64) {
  const bytes = crypto.getRandomValues(new Uint8Array(length))
  return encodeBase64Url(bytes).slice(0, length)
}

async function sha256(value) {
  const bytes = new TextEncoder().encode(value)
  const digest = await crypto.subtle.digest('SHA-256', bytes)
  return encodeBase64Url(new Uint8Array(digest))
}

function getStoredTokens() {
  const raw = window.localStorage.getItem(TOKEN_STORAGE_KEY)
  return raw ? JSON.parse(raw) : null
}

function storeTokens(tokens) {
  window.localStorage.setItem(TOKEN_STORAGE_KEY, JSON.stringify(tokens))
}

function clearTokens() {
  window.localStorage.removeItem(TOKEN_STORAGE_KEY)
}

function clearAuthFlowState() {
  clearTokens()
  window.sessionStorage.removeItem(CODE_VERIFIER_STORAGE_KEY)
}

function parseJwtClaims(token) {
  if (!token) return null

  const [, payload] = token.split('.')
  if (!payload) return null

  return JSON.parse(atob(payload.replace(/-/g, '+').replace(/_/g, '/')))
}

async function exchangeCodeForTokens(authConfig, code) {
  const verifier = window.sessionStorage.getItem(CODE_VERIFIER_STORAGE_KEY)
  if (!verifier) {
    throw new Error('Missing PKCE verifier in session storage.')
  }

  const response = await fetch(`${authConfig.hostedUiUrl}/oauth2/token`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      client_id: authConfig.userPoolClientId,
      code,
      redirect_uri: window.location.origin,
      code_verifier: verifier,
    }),
  })

  const tokens = await response.json()
  if (!response.ok) {
    throw new Error(tokens.error_description || tokens.error || 'Failed to exchange authorization code.')
  }

  window.sessionStorage.removeItem(CODE_VERIFIER_STORAGE_KEY)
  return tokens
}

function isInvalidGrant(error) {
  return String(error).includes('invalid_grant')
}

function resetAuthUrl() {
  window.history.replaceState({}, document.title, window.location.pathname)
}

async function refreshTokens(authConfig, refreshToken) {
  const response = await fetch(`${authConfig.hostedUiUrl}/oauth2/token`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      client_id: authConfig.userPoolClientId,
      refresh_token: refreshToken,
    }),
  })

  const tokens = await response.json()
  if (!response.ok) {
    throw new Error(tokens.error_description || tokens.error || 'Failed to refresh session.')
  }

  return {
    ...tokens,
    refresh_token: refreshToken,
  }
}

async function redirectToLogin(authConfig) {
  const verifier = randomString(96)
  const challenge = await sha256(verifier)

  window.sessionStorage.setItem(CODE_VERIFIER_STORAGE_KEY, verifier)

  const loginUrl = new URL(`${authConfig.hostedUiUrl}/login`)
  loginUrl.searchParams.set('client_id', authConfig.userPoolClientId)
  loginUrl.searchParams.set('response_type', 'code')
  loginUrl.searchParams.set('scope', authConfig.scopes.join(' '))
  loginUrl.searchParams.set('redirect_uri', window.location.origin)
  loginUrl.searchParams.set('code_challenge_method', 'S256')
  loginUrl.searchParams.set('code_challenge', challenge)

  window.location.assign(loginUrl.toString())
}

function signOut(authConfig) {
  clearTokens()

  const logoutUrl = new URL(`${authConfig.hostedUiUrl}/logout`)
  logoutUrl.searchParams.set('client_id', authConfig.userPoolClientId)
  logoutUrl.searchParams.set('logout_uri', window.location.origin)

  window.location.assign(logoutUrl.toString())
}

function browserInfoPayload(session) {
  return {
    job_id: `browser-telemetry-${crypto.randomUUID()}`,
    type: 'browser_telemetry',
    source: 'frontend',
    captured_at: new Date().toISOString(),
    auth: {
      username: session?.claims?.['cognito:username'] || null,
      email: session?.claims?.email || null,
      groups: session?.claims?.['cognito:groups'] || [],
    },
    page: {
      href: window.location.href,
      origin: window.location.origin,
      path: window.location.pathname,
      search: window.location.search,
      referrer: document.referrer || null,
      title: document.title,
    },
    browser: {
      user_agent: navigator.userAgent,
      language: navigator.language,
      languages: navigator.languages,
      platform: navigator.platform || null,
      cookie_enabled: navigator.cookieEnabled,
      online: navigator.onLine,
      hardware_concurrency: navigator.hardwareConcurrency ?? null,
      device_memory_gb: navigator.deviceMemory ?? null,
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      screen: {
        width: window.screen.width,
        height: window.screen.height,
        color_depth: window.screen.colorDepth,
        pixel_ratio: window.devicePixelRatio,
      },
      viewport: {
        width: window.innerWidth,
        height: window.innerHeight,
      },
    },
  }
}

function getCurrentPosition() {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error('Geolocation is not supported by this browser.'))
      return
    }

    navigator.geolocation.getCurrentPosition(resolve, reject, {
      enableHighAccuracy: true,
      timeout: 10_000,
      maximumAge: 60_000,
    })
  })
}

async function buildBrowserTelemetryPayload(session) {
  const payload = browserInfoPayload(session)

  try {
    const position = await getCurrentPosition()
    payload.location = {
      status: 'available',
      latitude: position.coords.latitude,
      longitude: position.coords.longitude,
      accuracy_meters: position.coords.accuracy,
      altitude_meters: position.coords.altitude,
      altitude_accuracy_meters: position.coords.altitudeAccuracy,
      heading_degrees: position.coords.heading,
      speed_mps: position.coords.speed,
    }
  } catch (error) {
    payload.location = {
      status: 'unavailable',
      error: String(error.message || error),
    }
  }

  return payload
}

export default function App() {
  const [authConfig, setAuthConfig] = useState(null)
  const [session, setSession] = useState(null)
  const [authError, setAuthError] = useState(null)
  const [lambdaData, setLambdaData] = useState(null)
  const [lambdaError, setLambdaError] = useState(null)
  const [ecsData, setEcsData] = useState(null)
  const [ecsError, setEcsError] = useState(null)
  const [publishData, setPublishData] = useState(null)
  const [publishError, setPublishError] = useState(null)
  const [publishPending, setPublishPending] = useState(false)
  const [publishedPayload, setPublishedPayload] = useState(null)

  useEffect(() => {
    let ignore = false

    async function bootstrap() {
      try {
        const config = await fetchJson(AUTH_CONFIG_PATH)
        if (ignore) return
        setAuthConfig(config)

        if (!config.enabled) {
          throw new Error('Authentication is disabled in auth-config.json. Update the local placeholder file or use the deployed frontend stack output.')
        }

        const url = new URL(window.location.href)
        const code = url.searchParams.get('code')
        const storedTokens = getStoredTokens()

        if (code) {
          try {
            const exchanged = await exchangeCodeForTokens(config, code)
            if (ignore) return
            storeTokens(exchanged)
            resetAuthUrl()
            setSession({
              tokens: exchanged,
              claims: parseJwtClaims(exchanged.id_token),
            })
            return
          } catch (error) {
            if (!isInvalidGrant(error)) {
              throw error
            }
            clearAuthFlowState()
            resetAuthUrl()
            await redirectToLogin(config)
            return
          }
        }

        if (storedTokens?.access_token) {
          const claims = parseJwtClaims(storedTokens.id_token)
          const expiresAt = claims?.exp ? claims.exp * 1000 : 0

          if (Date.now() < expiresAt - 60_000) {
            setSession({
              tokens: storedTokens,
              claims,
            })
            return
          }

          if (storedTokens.refresh_token) {
            try {
              const refreshed = await refreshTokens(config, storedTokens.refresh_token)
              if (ignore) return
              storeTokens(refreshed)
              setSession({
                tokens: refreshed,
                claims: parseJwtClaims(refreshed.id_token),
              })
              return
            } catch (error) {
              if (!isInvalidGrant(error)) {
                throw error
              }
              clearAuthFlowState()
            }
          }
        }

        await redirectToLogin(config)
      } catch (error) {
        if (!ignore) {
          setAuthError(error)
        }
      }
    }

    bootstrap()

    return () => {
      ignore = true
    }
  }, [])

  useEffect(() => {
    if (!session?.tokens?.access_token) {
      return
    }

    fetchJson('/api/', session.tokens.access_token)
      .then(setLambdaData)
      .catch(setLambdaError)

    fetchJson('/api/ecs', session.tokens.access_token)
      .then(setEcsData)
      .catch(setEcsError)
  }, [session])

  const renderTable = (data) => (
    <table border="1" cellPadding="8">
      <tbody>
        {Object.entries(data).map(([key, value]) => (
          <tr key={key}>
            <td><strong>{key}</strong></td>
            <td>{String(value)}</td>
          </tr>
        ))}
      </tbody>
    </table>
  )

  async function publishMessage() {
    if (!session?.tokens?.access_token) {
      return
    }

    setPublishPending(true)
    setPublishError(null)
    setPublishData(null)

    try {
      const payload = await buildBrowserTelemetryPayload(session)
      setPublishedPayload(payload)
      const data = await sendJson('/api/messages', {
        accessToken: session.tokens.access_token,
        method: 'POST',
        body: payload,
      })
      setPublishData(data)
    } catch (error) {
      setPublishError(error)
    } finally {
      setPublishPending(false)
    }
  }

  return (
    <div style={{ fontFamily: 'monospace', padding: '2rem' }}>
      <h1>Serverless App</h1>
      {authError && <p style={{ color: 'red' }}>Auth error: {String(authError)}</p>}
      {authConfig && session?.claims && (
        <div style={{ marginBottom: '2rem' }}>
          <p>Signed in as {session.claims.email || session.claims['cognito:username']}</p>
          <p>Groups: {String(session.claims['cognito:groups'] || authConfig.readonlyGroup)}</p>
          {authConfig.observabilityDashboardUrl && (
            <p>
              <a href={authConfig.observabilityDashboardUrl} target="_blank" rel="noreferrer">
                Open logging dashboard
              </a>
            </p>
          )}
          <button type="button" onClick={() => signOut(authConfig)}>Sign out</button>
        </div>
      )}
      <h2>Lambda Response</h2>
      {lambdaError && <p style={{ color: 'red' }}>Error: {String(lambdaError)}</p>}
      {lambdaData && renderTable(lambdaData)}
      {!lambdaData && !lambdaError && <p>Loading Lambda response...</p>}

      <h2 style={{ marginTop: '2rem' }}>Publish Worker Message</h2>
      <p>Send your current browser metadata, page context, timestamp, and geolocation to the shared worker SNS topic through the authenticated Lambda API.</p>
      <div style={{ marginTop: '1rem' }}>
        <button type="button" onClick={publishMessage} disabled={publishPending || !session?.tokens?.access_token}>
          {publishPending ? 'Collecting + publishing...' : 'Send browser telemetry'}
        </button>
      </div>
      {publishError && <p style={{ color: 'red' }}>Publish error: {String(publishError)}</p>}
      {publishData && renderTable(publishData)}
      {publishedPayload && (
        <>
          <h3 style={{ marginTop: '1rem' }}>Last Published Payload</h3>
          <pre style={{ maxWidth: '48rem', overflowX: 'auto', whiteSpace: 'pre-wrap' }}>
            {JSON.stringify(publishedPayload, null, 2)}
          </pre>
        </>
      )}

      <h2 style={{ marginTop: '2rem' }}>ECS Response</h2>
      {ecsError && <p style={{ color: 'red' }}>Error: {String(ecsError)}</p>}
      {ecsData && renderTable(ecsData)}
      {!ecsData && !ecsError && <p>Loading ECS response...</p>}
    </div>
  )
}
