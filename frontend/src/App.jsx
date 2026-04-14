import { useEffect, useState } from 'react'

async function fetchJson(url) {
  const response = await fetch(url)
  const text = await response.text()

  try {
    return JSON.parse(text)
  } catch {
    throw new Error(`${response.status} ${response.statusText}: ${text.slice(0, 200)}`)
  }
}

export default function App() {
  const [lambdaData, setLambdaData] = useState(null)
  const [lambdaError, setLambdaError] = useState(null)
  const [ecsData, setEcsData] = useState(null)
  const [ecsError, setEcsError] = useState(null)

  useEffect(() => {
    fetchJson('/api/')
      .then(setLambdaData)
      .catch(setLambdaError)

    fetchJson('/api/ecs')
      .then(setEcsData)
      .catch(setEcsError)
  }, [])

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

  return (
    <div style={{ fontFamily: 'monospace', padding: '2rem' }}>
      <h1>Serverless App</h1>
      <h2>Lambda Response</h2>
      {lambdaError && <p style={{ color: 'red' }}>Error: {String(lambdaError)}</p>}
      {lambdaData && renderTable(lambdaData)}
      {!lambdaData && !lambdaError && <p>Loading Lambda response...</p>}

      <h2 style={{ marginTop: '2rem' }}>ECS Response</h2>
      {ecsError && <p style={{ color: 'red' }}>Error: {String(ecsError)}</p>}
      {ecsData && renderTable(ecsData)}
      {!ecsData && !ecsError && <p>Loading ECS response...</p>}
    </div>
  )
}
