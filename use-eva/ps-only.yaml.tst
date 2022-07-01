diagnostics:

  # Data read
  # ---------
- data:
    type: IodaObsSpace
    datasets:
      - name: experiment
        filenames:
          - /work2/noaa/gsienkf/weihuang/jedi/case_study/surf/ioda_v2_data/out.12/sfc_ps_obs_2020011006_0003.nc4
        groups:
          - name: ObsValue
            variables: &variables [surface_pressure]
          - name: hofx_y_mean_xb0
          - name: EffectiveQC0
          - name: GsiHofX
          - name: GsiEffectiveQC
          - name: MetaData

  transforms:

    # Generate omb for GSI
    - transform: arithmetic
      new name: experiment::ObsValueMinushofx_y_mean_xb0::${variable}
      equals: experiment::ObsValue::${variable}-experiment::hofx_y_mean_xb0::${variable}
      for:
        variable: *variables

    # Generate omb for JEDI
    - transform: arithmetic
      new name: experiment::ObsValueMinusHofx::${variable}
      equals: experiment::ObsValue::${variable}-experiment::GsiHofX::${variable}
      for:
        variable: *variables

    # Generate hofx that passed QC for JEDI
    - transform: accept where
      new name: experiment::hofxPassedQc::${variable}
      starting field: experiment::GsiHofX::${variable}
      where:
        - experiment::GsiEffectiveQC::${variable} == 0
      for:
        variable: *variables

    # Generate GSI hofx that passed JEDI QC
    - transform: accept where
      new name: experiment::hofx_y_mean_xb0PassedQc::${variable}
      starting field: experiment::hofx_y_mean_xb0::${variable}
      where:
        - experiment::GsiEffectiveQC::${variable} == 0
      for:
        variable: *variables

    # Generate omb that passed QC for JEDI
    - transform: accept where
      new name: experiment::ObsValueMinushofxPassedQc::${variable}
      starting field: experiment::ObsValueMinusHofx::${variable}
      where:
        - experiment::GsiEffectiveQC::${variable} == 0
      for:
        variable: *variables

    # Generate omb that passed QC for GSI
    - transform: accept where
      new name: experiment::ObsValueMinushofx_y_mean_xb0PassedQc::${variable}
      starting field: experiment::ObsValueMinushofx_y_mean_xb0::${variable}
      where:
        - experiment::GsiEffectiveQC::${variable} == 0
      for:
        variable: *variables

  graphics:

    # JEDI h(x) vs Observations
    # -------------------------
    - batch figure:
        variables: *variables
      figure:
        layout: [1,1]
        title: 'Observations vs. JEDI h(x) | Surface Pressure | ${variable_title}'
        output name: observation_scatter_plots/surf/${variable}/jedi_hofx_vs_obs_surf_${variable}.png
      plots:
        - add_xlabel: 'Observation Value'
          add_ylabel: 'JEDI h(x)'
          add_grid:
          add_legend:
            loc: 'upper left'
          layers:
          - type: Scatter
            x:
              variable: experiment::ObsValue::${variable}
            y:
              variable: experiment::GsiHofX::${variable}
            markersize: 5
            color: 'black'
            label: 'JEDI h(x) versus obs (all obs)'
          - type: Scatter
            x:
              variable: experiment::ObsValue::${variable}
            y:
              variable: experiment::hofxPassedQc::${variable}
            markersize: 5
            color: 'red'
            label: 'JEDI h(x) versus obs (passed QC in JEDI)'

    # GSI h(x) vs Observations
    # -------------------------
    - batch figure:
        variables: *variables
      figure:
        layout: [1,1]
        title: 'Observations vs. GSI h(x) | Surface Pressure | ${variable_title}'
        output name: observation_scatter_plots/surf/${variable}/gsi_hofx_vs_obs_surf_${variable}.png
      plots:
        - add_xlabel: 'Observation Value'
          add_ylabel: 'GSI h(x)'
          add_grid:
          add_legend:
            loc: 'upper left'
          layers:
          - type: Scatter
            x:
              variable: experiment::ObsValue::${variable}
            y:
              variable: experiment::hofx_y_mean_xb0::${variable}
            markersize: 5
            color: 'black'
            label: 'GSI h(x) versus obs (all obs)'
          - type: Scatter
            x:
              variable: experiment::ObsValue::${variable}
            y:
              variable: experiment::hofx_y_mean_xb0PassedQc::${variable}
            markersize: 5
            color: 'red'
            label: 'GSI h(x) versus obs (passed QC in JEDI)'

    # JEDI h(x) vs GSI h(x)
    # ---------------------

    - batch figure:
        variables: *variables
      figure:
        layout: [1,1]
        title: 'JEDI h(x) vs. GSI h(x) | Surface Pressure | ${variable_title}'
        output name: observation_scatter_plots/surf/${variable}/gsi_hofx_vs_jedi_hofx_surf_${variable}.png
      plots:
        - add_xlabel: 'GSI h(x)'
          add_ylabel: 'JEDI h(x)'
          add_grid:
          add_legend:
            loc: 'upper left'
          layers:
          - type: Scatter
            x:
              variable: experiment::hofx_y_mean_xb0::${variable}
            y:
              variable: experiment::GsiHofX::${variable}
            markersize: 5
            color: 'black'
            label: 'JEDI h(x) versus GSI h(x)'
          - type: Scatter
            x:
              variable: experiment::hofx_y_mean_xb0PassedQc::${variable}
            y:
              variable: experiment::hofxPassedQc::${variable}
            markersize: 5
            color: 'red'
            label: 'JEDI h(x) versus GSI h(x) (passed QC in JEDI)'

    # JEDI omb vs GSI omb
    # ---------------------

    - batch figure:
        variables: *variables
      figure:
        layout: [1,1]
        title: 'JEDI omb vs. GSI omb| Surface Pressure | ${variable_title}'
        output name: observation_scatter_plots/surf/${variable}/gsi_omb_vs_jedi_omb_surf_${variable}.png
      plots:
        - add_xlabel: 'GSI observation minus h(x)'
          add_ylabel: 'JEDI observation minus h(x)'
          add_grid:
          add_legend:
            loc: 'upper left'
          layers:
          - type: Scatter
            x:
              variable: experiment::ObsValueMinushofx_y_mean_xb0::${variable}
            y:
              variable: experiment::ObsValueMinusHofx::${variable}
            markersize: 5
            color: 'black'
            label: 'GSI omb vs JEDI omb (all obs)'
          - type: Scatter
            x:
              variable: experiment::ObsValueMinushofx_y_mean_xb0PassedQc::${variable}
            y:
              variable: experiment::ObsValueMinushofxPassedQc::${variable}
            markersize: 5
            color: 'red'
            label: 'GSI omb vs JEDI omb (passed QC in JEDI)'
