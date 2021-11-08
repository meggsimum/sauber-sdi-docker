<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor xmlns="http://www.opengis.net/sld" xmlns:sld="http://www.opengis.net/sld" version="1.0.0" xmlns:ogc="http://www.opengis.net/ogc" xmlns:gml="http://www.opengis.net/gml">
  <UserLayer>
    <sld:LayerFeatureConstraints>
      <sld:FeatureTypeConstraint/>
    </sld:LayerFeatureConstraints>
    <sld:UserStyle>
      <sld:FeatureTypeStyle>
        <sld:Rule>
          <sld:RasterSymbolizer>
            <sld:ChannelSelection>
              <sld:GrayChannel>
                <sld:SourceChannelName>1</sld:SourceChannelName>
              </sld:GrayChannel>
            </sld:ChannelSelection>
            <sld:ColorMap type="ramp">
              <sld:ColorMapEntry color="#FFFFFF" quantity="0" opacity="0.1" label="noData"/>
              <sld:ColorMapEntry color="#1d63ff" quantity="1" label='0 µg/m³'/>
              <sld:ColorMapEntry color="#67b0ff" quantity="40" label="40 µg/m³"/>
              <sld:ColorMapEntry color="#c1e7f1" quantity="80" label="80 µg/m³"/>
              <sld:ColorMapEntry color="#ffff75" quantity="120" label="120 µg/m³"/>
              <sld:ColorMapEntry color="#ffba23" quantity="160" label="160 µg/m³"/>
              <sld:ColorMapEntry color="#ff0700" quantity="200" label="&gt;200 µg/m³"/>
            </sld:ColorMap>
          </sld:RasterSymbolizer>
        </sld:Rule>
      </sld:FeatureTypeStyle>
    </sld:UserStyle>
  </UserLayer>
</StyledLayerDescriptor>
