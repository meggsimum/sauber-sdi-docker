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
              <sld:ColorMapEntry color="#67b0ff" quantity="24" label="24 µg/m³"/>
              <sld:ColorMapEntry color="#c1e7f1" quantity="48" label="48 µg/m³"/>
              <sld:ColorMapEntry color="#ffff75" quantity="72" label="72 µg/m³"/>
              <sld:ColorMapEntry color="#ffba23" quantity="96" label="96 µg/m³"/>
              <sld:ColorMapEntry color="#ff0700" quantity="120" label="&gt;120 µg/m³"/>
            </sld:ColorMap>
          </sld:RasterSymbolizer>
        </sld:Rule>
      </sld:FeatureTypeStyle>
    </sld:UserStyle>
  </UserLayer>
</StyledLayerDescriptor>
