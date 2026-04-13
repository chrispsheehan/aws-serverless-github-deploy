import { useEffect, useState } from 'react'

export default function App() {
  const [lambdaData, setLambdaData] = useState(null)
  const [lambdaError, setLambdaError] = useState(null)
  const [ecsData, setEcsData] = useState(null)
  const [ecsError, setEcsError] = useState(null)

  useEffect(() => {
    fetch('/api/')
      .then((r) => r.json())
      .then(setLambdaData)
      .catch(setLambdaError)

    fetch('/api/ecs/')
      .then((r) => r.json())
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
