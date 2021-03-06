statePopulationService = ($http, decennial_url, tableauService, statesService, countiesService, congressionalDistrictService)->

  selectedState = "24"
  selectedDataType = "zip"

  dataConfiguration =
    zip:
      fieldNames: ['Population', 'Zipcode', 'State']
      fieldTypes: ['integer', 'integer', 'string']
    tract:
      fieldNames: ["Population", "State", "County", "Tract", "Block Group"]
      fieldTypes: ['integer', 'string', 'string', 'string', 'string']
    "congressional-district":
      fieldNames: ["Population", "State", "Congressional District", "Congressional District Code"]
      fieldTypes: ['integer', 'string', 'string', 'string']

  getColumnHeaders = ->
    dataConfiguration[selectedDataType]

  getData = (state, dataType)->
    selectedState = state
    selectedDataType = dataType
    callback = null
    byString = null
    switch selectedDataType
      when "zip"
        callback = getZipCodeData
        byString = "Zipcodes"
      when "tract"
        callback = getTractData
        byString = "County, Tract and Block Groups"
      when "congressional-district"
        callback = getCongressionalDistrictData
        byString = "Congressional Districts"
    connectionData =
      name: "Census data for #{statesService.getState(state.id).name} by #{byString}"
      data: state.id

    tableauService.submit getColumnHeaders(), callback, connectionData
    return

  getZipCodeData = (dummyLastRecordIndicator)->
    inVariable = "state:"+selectedState.id

    $http.get decennial_url,
      params:
        get: 'P0010001'
        for: 'zip code tabulation area:*'
        in: inVariable
    .then (response)->
      dataToReturn = []
      for row in response.data[1..]
        dataToReturn.push [row[0], row[2], statesService.getState(row[1]).name]
      tableauService.pushData dataToReturn, dataToReturn.length.toString(), false
    return

  getTractData = (countyIndex)->
    countyIndex ||= 0
    inVariable = "state:"+selectedState.id
    counties = countiesService.getCountyKeys(selectedState.id)
    $http.get decennial_url,
      params:
        get: 'P0010001'
        for: 'block group:*'
        in: inVariable+" county:"+counties[countyIndex]
    .then (response)->
      dataToReturn = []
      for row in response.data[1..]
        dataToReturn.push [row[0], statesService.getState(row[1]).name, countiesService.getCounty(row[1],row[2]).name, row[3], row[4]]
      countyIndex = parseInt(countyIndex)+1
      tableauService.pushData dataToReturn, countyIndex.toString(), countyIndex < counties.length
      return
    return

  getCongressionalDistrictData = ->
    inVariable = "state:"+selectedState.id
    $http.get decennial_url,
      params:
        get: 'P0010001'
        for: 'congressional district:*'
        in: inVariable
    .then (response)->
      dataToReturn = []
      for row in response.data[1..]
        dataToReturn.push [row[0], statesService.getState(row[1]).name, congressionalDistrictService.getCongressionalDistrict(row[1],row[2]).name, row[2]]
      tableauService.pushData dataToReturn, dataToReturn.length.toString(), false
      return
    return

  return {
    getData: getData
  }

angular
  .module 'censusApp.decennial'
  .factory 'statePopulationService', statePopulationService
  .config [
    '$httpProvider'
    ($httpProvider)->
        $httpProvider.defaults.useXDomain = true
        delete $httpProvider.defaults.headers.common['X-Requested-With']
  ]

statePopulationService.$inject = ['$http', 'decennial_url', 'tableauService', 'statesService', 'countiesService', 'congressionalDistrictService']
