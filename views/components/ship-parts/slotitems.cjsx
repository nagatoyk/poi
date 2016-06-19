path = require 'path-extra'
{$, $$, _, React, ReactBootstrap, ROOT} = window
{OverlayTrigger, Tooltip} = ReactBootstrap
{SlotitemIcon} = require '../etc/icon'
{getItemData} = require './slotitems-data'
getBackgroundStyle = ->
  if window.isDarkTheme
    backgroundColor: 'rgba(33, 33, 33, 0.7)'
  else
    backgroundColor: 'rgba(256, 256, 256, 0.7)'
Slotitems = React.createClass
  shouldComponentUpdate: (nextProps, nextState) ->
    not _.isEqual nextProps, @props
  render: ->
    <div className="slotitems">
    {
      {_slotitems} = window
      for item, i in @props.slots
        continue unless item?
        itemId = item.id
        itemOverlay = if item.isExist
          <Tooltip id="fleet-#{@props.fleet}-slot-#{@props.shipId}-item-#{i}-level">
            <div>
              <div>
                {i18n.resources.__ item.name}
                {
                  if item.level? and item.level > 0
                    <strong style={color: '#45A9A5'}> ★{item.level}</strong>
                }
                {
                  if item.alv? and 1 <= item.alv <= 7
                    <img className='alv-img' src={path.join('assets', 'img', 'airplane', "alv#{item.alv}.png")} />
                }
              </div>
              {
                if _slotitems[itemId]?
                  datas = getItemData _slotitems[itemId]
                  for data, index in datas
                    <div key="Slotitem-#{itemId}-#{index}">{data}</div>
              }
            </div>
          </Tooltip>

        itemSpan =
          <span>
            <SlotitemIcon key={itemId} className='slotitem-img' slotitemId={item.slotitemId} />
            <span className="slotitem-onslot
                            #{if (i == 5) or (item.slotitemId == 0) or (6 <= item.slotitemId <= 10) or (21 <= item.slotitemId <= 22) or (item.slotitemId == 33) then 'show' else 'hide'}
                            #{if item.onslot < item.maxeq then 'text-warning'}"
                            style={getBackgroundStyle()}>
              {if i == 5 then "+" else item.onslot}
            </span>
          </span>

        <div key={i} className="slotitem-container">
        {
          if itemOverlay
            <OverlayTrigger placement='left' overlay={itemOverlay}>
              {itemSpan}
            </OverlayTrigger>
          else
            itemSpan
        }
        </div>
    }
    </div>

module.exports = Slotitems
