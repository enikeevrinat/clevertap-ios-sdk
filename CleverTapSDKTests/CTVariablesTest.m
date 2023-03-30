//
//  CTVariablesTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 26.03.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTVariables+Tests.h"
#import "CTVarCacheMock.h"
#import "CTVariables.h"
#import "CTConstants.h"

@interface CTVariablesTest : XCTestCase

@property(strong, nonatomic) CTVariables *variables;

@end

@implementation CTVariablesTest

- (void)setUp {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"id" accountToken:@"token" accountRegion:@"eu"];
    CTDeviceInfo *deviceInfo = [[CTDeviceInfo alloc] initWithConfig:config andCleverTapID:@"test"];
    CTVarCacheMock *varCache = [[CTVarCacheMock alloc] initWithConfig:config deviceInfo:deviceInfo];
    self.variables = [[CTVariables alloc] initWithConfig:config deviceInfo:deviceInfo varCache:varCache];
}

- (void)tearDown {
    self.variables = nil;
}

- (void)testVarCacheNotNil {
    XCTAssertNotNil(self.variables.varCache);
}

#pragma mark Sync Variables
- (void)testSyncVars {
    NSString *varName = @"var1";
    NSString *varValue = @"value1";
    
    CTVar *definedVar = [self.variables define:varName with:varValue kind:CT_KIND_STRING];
    
    NSDictionary *payload = [self.variables varsPayload];
    
    XCTAssertEqualObjects(payload[@"type"], CT_PE_VARS_PAYLOAD_TYPE);
    NSDictionary *vars = [payload objectForKey:CT_PE_VARS_PAYLOAD_KEY];
    NSDictionary *titleMap = [vars objectForKey:varName];
    XCTAssertEqualObjects(titleMap[CT_PE_DEFAULT_VALUE], varValue);
    XCTAssertEqualObjects(titleMap[CT_PE_VAR_TYPE], definedVar.kind);
}

- (void)testSyncVarsComplex {
    [self.variables define:@"var1" with:@"value1" kind:CT_KIND_STRING];
    [self.variables define:@"var2.var22" with:@"value2" kind:CT_KIND_STRING];
    [self.variables define:@"var3" with:@YES kind:CT_KIND_BOOLEAN];
    [self.variables define:@"var4" with:@1234 kind:CT_KIND_INT];
    [self.variables define:@"var5" with:@12.34 kind:CT_KIND_FLOAT];
    [self.variables define:@"var6" with:@{
        @"var7": @"value7",
        @"var8": @"value8"
    } kind:CT_KIND_DICTIONARY];
    
    NSDictionary *expected = @{
        @"type": @"varsPayload",
        @"vars": @{
            @"var1": @{
                @"defaultValue": @"value1",
                @"type": @"string"
            },
            @"var2.var22": @{
                @"defaultValue": @"value2",
                @"type": @"string"
            },
            @"var3": @{
                @"defaultValue": @1,
                @"type": @"boolean"
            },
            @"var4": @{
                @"defaultValue": @1234,
                @"type": @"number"
            },
            @"var5": @{
                @"defaultValue": @12.34,
                @"type": @"number"
            },
            @"var6.var7": @{
                @"defaultValue": @"value7",
            },
            @"var6.var8": @{
                @"defaultValue": @"value8",
            },
        }
    };
    
    NSDictionary *actual = [self.variables varsPayload];
    XCTAssertEqualObjects(actual, expected);
}

- (void)testSyncVarsWithDots {
    [self.variables define:@"var1.var2" with:@"value2" kind:CT_KIND_STRING];
    [self.variables define:@"var1.var3" with:@"value3" kind:CT_KIND_STRING];
    [self.variables define:@"var1.var4.var5" with:@YES kind:CT_KIND_BOOLEAN];
    [self.variables define:@"var1.var4.var6" with:@1234 kind:CT_KIND_INT];
    [self.variables define:@"var7.var8" with:@12.34 kind:CT_KIND_FLOAT];
    
    NSDictionary *expected = @{
        @"type": @"varsPayload",
        @"vars": @{
            @"var1.var2": @{
                @"defaultValue": @"value2",
                @"type": @"string"
            },
            @"var1.var3": @{
                @"defaultValue": @"value3",
                @"type": @"string"
            },
            @"var1.var4.var5": @{
                @"defaultValue": @1,
                @"type": @"boolean"
            },
            @"var1.var4.var6": @{
                @"defaultValue": @1234,
                @"type": @"number"
            },
            @"var7.var8": @{
                @"defaultValue": @12.34,
                @"type": @"number"
            }
        }
    };
    
    NSDictionary *actual = [self.variables varsPayload];
    XCTAssertEqualObjects(actual, expected);
}

- (void)testSyncVarsWithDotsAndDictionaries {
    [self.variables define:@"var1.var2" with:@"value2" kind:CT_KIND_STRING];
    [self.variables define:@"var1.var4" with:@{
        @"var5": @NO,
        @"var6": @1234
    } kind:CT_KIND_DICTIONARY];
    [self.variables define:@"var7.var8" with:@"value8" kind:CT_KIND_STRING];
    [self.variables define:@"var7" with:@{
        @"var9": @12.34
    } kind:CT_KIND_DICTIONARY];
    [self.variables define:@"var7.var10" with:@"value10" kind:CT_KIND_STRING];

    
    NSDictionary *expected = @{
        @"type": @"varsPayload",
        @"vars": @{
            @"var1.var2": @{
                @"defaultValue": @"value2",
                @"type": @"string"
            },
            @"var1.var4.var5": @{
                @"defaultValue": @0
            },
            @"var1.var4.var6": @{
                @"defaultValue": @1234
            },
            @"var7.var8": @{
                @"defaultValue": @"value8",
                @"type": @"string"
            },
            @"var7.var9": @{
                @"defaultValue": @12.34
            },
            @"var7.var10": @{
                @"defaultValue": @"value10",
                @"type": @"string"
            }
        }
    };
    
    NSDictionary *actual = [self.variables varsPayload];
    XCTAssertEqualObjects(actual, expected);
}

- (void)testSyncVarsWithInvalidArray {
    [self.variables define:@"var1" with:@"value1" kind:CT_KIND_STRING];
    [self.variables define:@"var2" with:@{
        @"var3": @[ @"arr" ],
        @"var4": @"value4"
    } kind:CT_KIND_DICTIONARY];
    
    // The array will be dropped
    NSDictionary *expected = @{
        @"type": @"varsPayload",
        @"vars": @{
            @"var1": @{
                @"defaultValue": @"value1",
                @"type": @"string"
            },
            @"var2.var4": @{
                @"defaultValue": @"value4"
            }
        }
    };
    
    NSDictionary *actual = [self.variables varsPayload];
    XCTAssertEqualObjects(actual, expected);
}

- (void)testSyncVarsWithEmpty {
    NSDictionary *expected = @{
        @"type": @"varsPayload",
        @"vars": @{}
    };
    
    NSDictionary *actual = [self.variables varsPayload];
    XCTAssertEqualObjects(actual, expected);
}

#pragma mark Unflatten Variables
- (void)testUnflattenVariables {
    NSDictionary *flat = @{
        @"a.b.c.d": @"d value",
        @"a.b.c.dd": @"dd value",
        @"a.e": @"e value",
        @"a.b.bb": @"bb value",
    };
    NSDictionary *expected = @{
        @"a": @{
            @"b": @{
                @"c": @{
                    @"d": @"d value",
                    @"dd": @"dd value"
                },
                @"bb": @"bb value"
            },
            @"e": @"e value"
        }
    };
    NSDictionary *result = [self.variables unflatten:flat];
    XCTAssertEqualObjects(result, expected);
}

- (void)testUnflattenWithFlatInput {
    NSDictionary *inputDict = @{
        @"a": @"value1",
        @"b": @123
    };
    
    NSDictionary *expectedOutput = @{
        @"a": @"value1",
        @"b": @123
    };
    
    NSDictionary *actualOutput = [self.variables unflatten:inputDict];
    XCTAssertEqualObjects(actualOutput, expectedOutput);
}

- (void)testUnflattenWithDictionaryInput {
    NSDictionary *inputDict = @{
        @"testVarName.a.b": @{
            @"defaultValue": @"value1"
        },
        @"testVarName.a.c.d": @{
            @"defaultValue": @"value2"
        },
        @"testVarName.e": @{
            @"defaultValue": @"value3"
        },
        @"testVarName.f": @{
            @"defaultValue": @"value4"
        }
    };
    
    NSDictionary *expectedOutput = @{
        @"testVarName": @{
            @"a": @{
                @"b": @{
                    @"defaultValue": @"value1"
                },
                @"c": @{
                    @"d": @{
                        @"defaultValue": @"value2"
                    }
                }
            },
            @"e": @{
                @"defaultValue": @"value3"
            },
            @"f": @{
                @"defaultValue": @"value4"
            }
        }
    };
    
    NSDictionary *actualOutput = [self.variables unflatten:inputDict];
    XCTAssertEqualObjects(actualOutput, expectedOutput);
}

- (void)testUnflattenWithEmptyInput {
    NSDictionary *inputDict = @{};
    
    NSDictionary *expectedOutput = @{};
    
    NSDictionary *actualOutput = [self.variables unflatten:inputDict];
    XCTAssertEqualObjects(actualOutput, expectedOutput);
}

- (void)testUnflattenWithInvalidDictionary {
    NSDictionary *inputDict = @{
        @"a.b.c.d": @"d value",
        @"a.b.c": @"c value",
        @"a.e": @"e value",
        @"a.b": @"b value",
    };
    
    NSDictionary *expectedOutput = @{
        @"a": @{
            @"b": @"b value",
            @"e": @"e value"
        }
    };
    
    NSDictionary *actualOutput = [self.variables unflatten:inputDict];
    XCTAssertEqualObjects(actualOutput, expectedOutput);
}

- (void)testUnflattenWithInvalidDictionaryDifferentOrder {
    NSDictionary *inputDict = @{
        @"a.b.c": @"c value",
        @"a.b.c.d": @"d value",
        @"a.e": @"e value",
        @"a.b": @"b value",
    };
    
    NSDictionary *expectedOutput = @{
        @"a": @{
            @"b": @"b value",
            @"e": @"e value"
        }
    };
    
    NSDictionary *actualOutput = [self.variables unflatten:inputDict];
    XCTAssertEqualObjects(actualOutput, expectedOutput);
}

- (void)testUnflattenWithInvalidInputArray {
    NSDictionary *inputDict = @{
        @"a": @[ @"value2" ]
    };
    
    NSDictionary *expectedOutput = @{
        @"a": @[ @"value2" ]
    };
    
    NSDictionary *actualOutput = [self.variables unflatten:inputDict];
    XCTAssertEqualObjects(actualOutput, expectedOutput);
}

#pragma mark Flatten Variables

- (void)testFlatten {
    NSDictionary *inputDict = @{
        @"Team": @{
            @"TeamName": @"Testing",
            @"Designation": @"Tester"
        },
        @"Name": @"CleverTap",
        @"EmployeeID": @123
    };
    
    NSString *varName = @"Employee";
    NSDictionary *expected = @{
        @"Employee.Team.TeamName": @{
            @"defaultValue": @"Testing"
        },
        @"Employee.Team.Designation": @{
            @"defaultValue": @"Tester"
        },
        @"Employee.Name": @{
            @"defaultValue": @"CleverTap"
        },
        @"Employee.EmployeeID": @{
            @"defaultValue": @123
        }
    };
    
    NSDictionary *result = [self.variables flatten:inputDict varName:varName];
    XCTAssertEqualObjects(result, expected);
}

- (void)testFlattenWithMultipleDictionaries {
    NSDictionary *inputDict = @{
        @"a": @{
            @"b": @"value1",
            @"c": @{
                @"d": @"value2",
                @"e": @{
                    @"f": @"value3",
                    @"g": @"value4"
                },
                @"h": @"value5"
            },
            @"i": @"value6"
        },
        @"j": @"value7",
        @"k": @{
            @"l": @"value8",
            @"m": @{
                @"n": @"value9"
            }
        }
    };
    
    NSString *varName = @"testVarName";
    NSDictionary *expected = @{
        @"testVarName.a.b": @{
            @"defaultValue": @"value1"
        },
        @"testVarName.a.c.d": @{
            @"defaultValue": @"value2"
        },
        @"testVarName.a.c.e.f": @{
            @"defaultValue": @"value3"
        },
        @"testVarName.a.c.e.g": @{
            @"defaultValue": @"value4"
        },
        @"testVarName.a.c.h": @{
            @"defaultValue": @"value5"
        },
        @"testVarName.a.i": @{
            @"defaultValue": @"value6"
        },
        @"testVarName.j": @{
            @"defaultValue": @"value7"
        },
        @"testVarName.k.l": @{
            @"defaultValue": @"value8"
        },
        @"testVarName.k.m.n": @{
            @"defaultValue": @"value9"
        },
    };
    
    NSDictionary *actual = [self.variables flatten:inputDict varName:varName];
    XCTAssertEqualObjects(actual, expected);
}

- (void)testFlattenWithEmptyInput {
    NSDictionary *inputDict = @{};
    
    NSString *varName = @"testVarName";
    NSDictionary *expectedOutput = @{};
    
    NSDictionary *actualOutput = [self.variables flatten:inputDict varName:varName];
    XCTAssertEqualObjects(actualOutput, expectedOutput);
}

- (void)testFlattenWithInvalidInputArray {
    NSDictionary *inputDict = @{
        @"a": @"value1",
        @"b": @123,
        @"c": @[ @"value2" ]
    };
    
    NSString *varName = @"testVarName";
    // The array will be dropped
    NSDictionary *expectedOutput = @{
        @"testVarName.a": @{
            @"defaultValue": @"value1"
        },
        @"testVarName.b": @{
            @"defaultValue": @123
        }
    };
    
    NSDictionary *actualOutput = [self.variables flatten:inputDict varName:varName];
    XCTAssertEqualObjects(actualOutput, expectedOutput);
}

@end

