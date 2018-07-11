import React from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'

const TopReferrers = props => (
<div><pre>{props.data}</pre></div>
)

TopReferrers.defaultProps = {
  data: 'error retrieving data'
}
TopReferrers.propTypes = {
  data: PropTypes.string
}

document.addEventListener('DOMContentLoaded', () => {
  const node = document.getElementById('top_referrers_data')
  const data = JSON.stringify(JSON.parse(node.getAttribute('data')),null,4)
  ReactDOM.render(
    <TopReferrers data={data}/>,
    document.body.appendChild(document.createElement('div')),
  )
})
