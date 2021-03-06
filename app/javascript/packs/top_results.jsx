import React from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'

const TopResult = props => (
<div><pre>{props.data}</pre></div>
)

TopResult.defaultProps = {
  data: 'error retrieving data'
}
TopResult.propTypes = {
  data: PropTypes.string
}

document.addEventListener('DOMContentLoaded', () => {
  const node = document.getElementById('top_results_data')
  const data = JSON.stringify(JSON.parse(node.getAttribute('data')),null,4)
  ReactDOM.render(
    <TopResult data={data}/>,
    document.body.appendChild(document.createElement('div')),
  )
})
