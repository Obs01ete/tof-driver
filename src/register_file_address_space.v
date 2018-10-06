localparam [6:0] ADDRESS_DEBUG_0                = 7'h40;
localparam [6:0] ADDRESS_DEBUG_1                = 7'h41;
localparam [6:0] ADDRESS_DEBUG_2                = 7'h42;
localparam [6:0] ADDRESS_DEBUG_3                = 7'h43;
localparam [6:0] ADDRESS_DEBUG_4                = 7'h44;
localparam [6:0] ADDRESS_DEBUG_5                = 7'h45;
localparam [6:0] ADDRESS_DEBUG_6                = 7'h46;
localparam [6:0] ADDRESS_DEBUG_7                = 7'h47;

localparam [6:0] ADDRESS_START_CYCLE            = 7'h50;
localparam [6:0] ADDRESS_CYCLE_FINISHED         = 7'h51;
localparam [6:0] ADDRESS_INTEGRATION_TIME_0     = 7'h52;
localparam [6:0] ADDRESS_INTEGRATION_TIME_1     = 7'h53;
localparam [6:0] ADDRESS_INTEGRATION_TIME_2     = 7'h54;
localparam [6:0] ADDRESS_OVERRIDE_ENABLE_ROI    = 7'h55;
localparam [6:0] ADDRESS_ENABLE_CYCLE_EMULATION = 7'h56;
localparam [6:0] ADDRESS_ADC_CTRL               = 7'h57;

localparam [6:0] ADDRESS_SNS_ADDR               = 7'h68;
localparam [6:0] ADDRESS_SNS_VALUE              = 7'h69;
localparam [6:0] ADDRESS_SNS_BUSY               = 7'h6A;
localparam [6:0] ADDRESS_SNS_ACQUIRE            = 7'h6B;
localparam [6:0] ADDRESS_MUX_CE_A_ND            = 7'h6C;

localparam [6:0] ADDRESS_CFG_REGISTER           = 7'h71;

localparam [6:0] ADDRESS_ADC_ADDR               = 7'h72;
localparam [6:0] ADDRESS_ADC_VALUE              = 7'h73;
localparam [6:0] ADDRESS_ADC_BUSY               = 7'h74;
localparam [6:0] ADDRESS_ADC_ACQUIRE            = 7'h75;
localparam [6:0] ADDRESS_ADC_VALUE_HIGHER_BYTE  = 7'h76;

localparam [6:0] ADDRESS_MODSEL_DIVISOR         = 7'h78;
localparam [6:0] ADDRESS_MODLED_PHASE           = 7'h79;
localparam [6:0] ADDRESS_MODLED_PHASE_1         = 7'h7A;
localparam [6:0] ADDRESS_MODLED_PHASE_2         = 7'h7B;
localparam [6:0] ADDRESS_MODLED_PHASE_3         = 7'h7C;
localparam [6:0] ADDRESS_MULTICYCLE_MODE        = 7'h7D;

localparam [0:0] RF_WRITE_BIT = 1'b1;
localparam [0:0] RF_READ_BIT = 1'b0;
