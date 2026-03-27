import { useEffect, useState } from 'react'

export default function App() {
  const [data, setData] = useState(null)
  const [error, setError] = useState(null)

  useEffect(() => {
    fetch('/api/')
      .then((r) => r.json())
      .then(setData)
      .catch(setError)
  }, [])

  return (
    <div style={{ fontFamily: 'monospace', padding: '2rem' }}>
      <h1>Serverless App</h1>
      {error && <p style={{ color: 'red' }}>Error: {String(error)}</p>}
      {data && (
        <table border="1" cellPadding="8">
          <tbody>
            {Object.entries(data).map(([k, v]) => (
              <tr key={k}>
                <td><strong>{k}</strong></td>
                <td>{String(v)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
      {!data && !error && <p>Loading...</p>}
    </div>
  )
}
