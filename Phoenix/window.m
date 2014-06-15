#import "lua/lauxlib.h"

int window_gc(lua_State* L) {
    AXUIElementRef* winptr = lua_touserdata(L, 1);
    CFRelease(*winptr);
    return 0;
}

void window_push_window_as_userdata(lua_State* L, AXUIElementRef win) {
    AXUIElementRef* winptr = lua_newuserdata(L, sizeof(AXUIElementRef));
    *winptr = win;
    // [ud]
    
    if (luaL_newmetatable(L, "window"))
    // [ud, md]
    {
        lua_pushcfunction(L, window_gc); // [ud, md, gc]
        lua_setfield(L, -2, "__gc");     // [ud, md]
    }
    // [ud, md]
    
    lua_setmetatable(L, -2);
    // [ud]
}

static AXUIElementRef system_wide_element() {
    static AXUIElementRef element;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        element = AXUIElementCreateSystemWide();
    });
    return element;
}

int window_get_focused_window(lua_State* L) {
    CFTypeRef app;
    AXUIElementCopyAttributeValue(system_wide_element(), kAXFocusedApplicationAttribute, &app);
    
    if (app) {
        CFTypeRef win;
        AXError result = AXUIElementCopyAttributeValue(app, (CFStringRef)NSAccessibilityFocusedWindowAttribute, &win);
        
        CFRelease(app);
        
        if (result == kAXErrorSuccess) {
            window_push_window_as_userdata(L, win);
            return 1;
        }
    }
    
    return 0;
}

static id get_window_prop(AXUIElementRef win, NSString* propType, id defaultValue) {
    CFTypeRef _someProperty;
    if (AXUIElementCopyAttributeValue(win, (__bridge CFStringRef)propType, &_someProperty) == kAXErrorSuccess)
        return CFBridgingRelease(_someProperty);
    
    return defaultValue;
}

int window_title(lua_State* L) {
    AXUIElementRef* winptr = lua_touserdata(L, 1);
    NSString* title = get_window_prop(*winptr, NSAccessibilityTitleAttribute, @"");
    lua_pushstring(L, [title UTF8String]);
    return 1;
}

static NSString* window_subrole(AXUIElementRef win) {
    return get_window_prop(win, NSAccessibilitySubroleAttribute, @"");
}

int window_is_standard(lua_State* L) {
    AXUIElementRef* winptr = lua_touserdata(L, 1);
    BOOL is_standard = [window_subrole(*winptr) isEqualToString: (__bridge NSString*)kAXStandardWindowSubrole];
    lua_pushboolean(L, is_standard);
    return 1;
}

int window_topleft(lua_State* L) {
    AXUIElementRef* winptr = lua_touserdata(L, 1);
    
    CFTypeRef positionStorage;
    AXError result = AXUIElementCopyAttributeValue(*winptr, (CFStringRef)NSAccessibilityPositionAttribute, &positionStorage);

    CGPoint topLeft;
    if (result == kAXErrorSuccess) {
        if (!AXValueGetValue(positionStorage, kAXValueCGPointType, (void *)&topLeft)) {
            NSLog(@"could not decode topLeft");
            topLeft = CGPointZero;
        }
    }
    else {
        NSLog(@"could not get window topLeft");
        topLeft = CGPointZero;
    }

    if (positionStorage)
        CFRelease(positionStorage);
    
    lua_pushnumber(L, topLeft.x);
    lua_pushnumber(L, topLeft.y);
    return 2;
}

int window_size(lua_State* L) {
    AXUIElementRef* winptr = lua_touserdata(L, 1);
    
    CFTypeRef sizeStorage;
    AXError result = AXUIElementCopyAttributeValue(*winptr, (CFStringRef)NSAccessibilitySizeAttribute, &sizeStorage);

    CGSize size;
    if (result == kAXErrorSuccess) {
        if (!AXValueGetValue(sizeStorage, kAXValueCGSizeType, (void *)&size)) {
            NSLog(@"could not decode topLeft");
            size = CGSizeZero;
        }
    }
    else {
        NSLog(@"could not get window size");
        size = CGSizeZero;
    }

    if (sizeStorage)
        CFRelease(sizeStorage);
    
    lua_pushnumber(L, size.width);
    lua_pushnumber(L, size.height);
    return 2;
}



















//+ (NSArray*) allWindows;
//+ (NSArray*) visibleWindows;
//+ (PHWindow*) focusedWindow;
//+ (NSArray*) visibleWindowsMostRecentFirst;
//- (NSArray*) otherWindowsOnSameScreen;
//- (NSArray*) otherWindowsOnAllScreens;
//
//
//- (CGRect) frame;
//- (CGPoint) topLeft;
//- (CGSize) size;
//
//- (void) setFrame:(CGRect)frame;
//- (void) setTopLeft:(CGPoint)thePoint;
//- (void) setSize:(CGSize)theSize;
//
//
//- (void) maximize;
//- (void) minimize;
//- (void) unMinimize;
//
//
//- (NSScreen*) screen;
//- (PHApp*) app;
//
//- (BOOL) focusWindow;
//
//- (void) focusWindowLeft;
//- (void) focusWindowRight;
//- (void) focusWindowUp;
//- (void) focusWindowDown;
//
//- (NSArray*) windowsToWest;
//- (NSArray*) windowsToEast;
//- (NSArray*) windowsToNorth;
//- (NSArray*) windowsToSouth;
//
//
//- (BOOL) isWindowMinimized;
//
//
//
//
//
//
//
//
//
//+ (NSArray*) visibleWindows {
//    return [[self allWindows] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(PHWindow* win, NSDictionary *bindings) {
//        return ![[win app] isHidden]
//        && ![win isWindowMinimized]
//        && [win isNormalWindow];
//    }]];
//}
//
//- (NSArray*) otherWindowsOnSameScreen {
//    return [[PHWindow visibleWindows] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(PHWindow* win, NSDictionary *bindings) {
//        return !CFEqual(self.window, win.window) && [[self screen] isEqual: [win screen]];
//    }]];
//}
//
//- (NSArray*) otherWindowsOnAllScreens {
//    return [[PHWindow visibleWindows] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(PHWindow* win, NSDictionary *bindings) {
//        return !CFEqual(self.window, win.window);
//    }]];
//}
//
//- (CGRect) frame {
//    CGRect r;
//    r.origin = [self topLeft];
//    r.size = [self size];
//    return r;
//}
//
//- (void) setFrame:(CGRect)frame {
//    [self setSize: frame.size];
//    [self setTopLeft: frame.origin];
//    [self setSize: frame.size];
//}
//
//
//- (void) setTopLeft:(CGPoint)thePoint {
//    CFTypeRef positionStorage = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&thePoint));
//    AXUIElementSetAttributeValue(self.window, (CFStringRef)NSAccessibilityPositionAttribute, positionStorage);
//    if (positionStorage)
//        CFRelease(positionStorage);
//}
//
//- (void) setSize:(CGSize)theSize {
//    CFTypeRef sizeStorage = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&theSize));
//    AXUIElementSetAttributeValue(self.window, (CFStringRef)NSAccessibilitySizeAttribute, sizeStorage);
//    if (sizeStorage)
//        CFRelease(sizeStorage);
//}
//
//- (NSScreen*) screen {
//    CGRect windowFrame = [self frame];
//    
//    CGFloat lastVolume = 0;
//    NSScreen* lastScreen = nil;
//    
//    for (NSScreen* screen in [NSScreen screens]) {
//        CGRect screenFrame = [screen frameIncludingDockAndMenu];
//        CGRect intersection = CGRectIntersection(windowFrame, screenFrame);
//        CGFloat volume = intersection.size.width * intersection.size.height;
//        
//        if (volume > lastVolume) {
//            lastVolume = volume;
//            lastScreen = screen;
//        }
//    }
//    
//    return lastScreen;
//}
//
//- (void) maximize {
//    CGRect screenRect = [[self screen] frameWithoutDockOrMenu];
//    [self setFrame: screenRect];
//}
//
//- (void) minimize {
//    [self setWindowMinimized:YES];
//}
//
//- (void) unMinimize {
//    [self setWindowMinimized:NO];
//}
//
//- (BOOL) focusWindow {
//    AXError changedMainWindowResult = AXUIElementSetAttributeValue(self.window, (CFStringRef)NSAccessibilityMainAttribute, kCFBooleanTrue);
//    if (changedMainWindowResult != kAXErrorSuccess) {
//        NSLog(@"ERROR: Could not change focus to window");
//        return NO;
//    }
//    
//    NSRunningApplication* app = [NSRunningApplication runningApplicationWithProcessIdentifier:[self processIdentifier]];
//    return [app activateWithOptions:NSApplicationActivateIgnoringOtherApps];
//}
//
//- (pid_t) processIdentifier {
//    pid_t pid = 0;
//    AXError result = AXUIElementGetPid(self.window, &pid);
//    if (result == kAXErrorSuccess)
//        return pid;
//    else
//        return 0;
//}
//
//- (PHApp*) app {
//    return [[PHApp alloc] initWithPID:[self processIdentifier]];
//}
//
//- (BOOL) setWindowProperty:(NSString*)propType withValue:(id)value {
//    if ([value isKindOfClass:[NSNumber class]]) {
//        AXError result = AXUIElementSetAttributeValue(self.window, (__bridge CFStringRef)(propType), (__bridge CFTypeRef)(value));
//        if (result == kAXErrorSuccess)
//            return YES;
//    }
//    return NO;
//}
//
//- (NSString *) role {
//    return [self getWindowProperty:NSAccessibilityRoleAttribute withDefaultValue:@""];
//}
//
//- (BOOL) isWindowMinimized {
//    return [[self getWindowProperty:NSAccessibilityMinimizedAttribute withDefaultValue:@(NO)] boolValue];
//}
//
//- (void) setWindowMinimized:(BOOL)flag
//{
//    [self setWindowProperty:NSAccessibilityMinimizedAttribute withValue:[NSNumber numberWithLong:flag]];
//}
//
//// focus
//
//
//NSPoint SDMidpoint(NSRect r) {
//    return NSMakePoint(NSMidX(r), NSMidY(r));
//}
//
//- (NSArray*) windowsInDirectionFn:(double(^)(double angle))whichDirectionFn
//                shouldDisregardFn:(BOOL(^)(double deltaX, double deltaY))shouldDisregardFn
//{
//    PHWindow* thisWindow = [PHWindow focusedWindow];
//    NSPoint startingPoint = SDMidpoint([thisWindow frame]);
//    
//    NSArray* otherWindows = [thisWindow otherWindowsOnAllScreens];
//    NSMutableArray* closestOtherWindows = [NSMutableArray arrayWithCapacity:[otherWindows count]];
//    
//    for (PHWindow* win in otherWindows) {
//        NSPoint otherPoint = SDMidpoint([win frame]);
//        
//        double deltaX = otherPoint.x - startingPoint.x;
//        double deltaY = otherPoint.y - startingPoint.y;
//        
//        if (shouldDisregardFn(deltaX, deltaY))
//            continue;
//        
//        double angle = atan2(deltaY, deltaX);
//        double distance = hypot(deltaX, deltaY);
//        
//        double angleDifference = whichDirectionFn(angle);
//        
//        double score = distance / cos(angleDifference / 2.0);
//        
//        [closestOtherWindows addObject:@{
//                                         @"score": @(score),
//                                         @"win": win,
//                                         }];
//    }
//    
//    NSArray* sortedOtherWindows = [closestOtherWindows sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* pair1, NSDictionary* pair2) {
//        return [[pair1 objectForKey:@"score"] compare: [pair2 objectForKey:@"score"]];
//    }];
//    
//    return sortedOtherWindows;
//}
//
//- (void) focusFirstValidWindowIn:(NSArray*)closestWindows {
//    for (PHWindow* win in closestWindows) {
//        if ([win focusWindow])
//            break;
//    }
//}
//
//- (NSArray*) windowsToWest {
//    return [[self windowsInDirectionFn:^double(double angle) { return M_PI - abs(angle); }
//                     shouldDisregardFn:^BOOL(double deltaX, double deltaY) { return (deltaX >= 0); }] valueForKeyPath:@"win"];
//}
//
//- (NSArray*) windowsToEast {
//    return [[self windowsInDirectionFn:^double(double angle) { return 0.0 - angle; }
//                     shouldDisregardFn:^BOOL(double deltaX, double deltaY) { return (deltaX <= 0); }] valueForKeyPath:@"win"];
//}
//
//- (NSArray*) windowsToNorth {
//    return [[self windowsInDirectionFn:^double(double angle) { return -M_PI_2 - angle; }
//                     shouldDisregardFn:^BOOL(double deltaX, double deltaY) { return (deltaY >= 0); }] valueForKeyPath:@"win"];
//}
//
//- (NSArray*) windowsToSouth {
//    return [[self windowsInDirectionFn:^double(double angle) { return M_PI_2 - angle; }
//                     shouldDisregardFn:^BOOL(double deltaX, double deltaY) { return (deltaY <= 0); }] valueForKeyPath:@"win"];
//}
//
//- (void) focusWindowLeft {
//    [self focusFirstValidWindowIn:[self windowsToWest]];
//}
//
//- (void) focusWindowRight {
//    [self focusFirstValidWindowIn:[self windowsToEast]];
//}
//
//- (void) focusWindowUp {
//    [self focusFirstValidWindowIn:[self windowsToNorth]];
//}
//
//- (void) focusWindowDown {
//    [self focusFirstValidWindowIn:[self windowsToSouth]];
//}
//
//@end






















//// XXX: undocumented API.  We need this to match dictionary entries returned by CGWindowListCopyWindowInfo (which
//// appears to be the *only* way to get a list of all windows on the system in "most-recently-used first" order) against
//// AXUIElementRef's returned by AXUIElementCopyAttributeValues
//AXError _AXUIElementGetWindow(AXUIElementRef, CGWindowID* out);
//
//+ (NSArray*) visibleWindowsMostRecentFirst {
//    // This gets windows sorted by most-recently-used criteria.  The
//    // first one will be the active window.
//    CFArrayRef visible_win_info = CGWindowListCopyWindowInfo(
//                                                             kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements,
//                                                             kCGNullWindowID);
//
//    // But we only got some dictionaries containing info.  Need to get
//    // the actual AXUIMyHeadHurts for each of them and create SDWindow-s.
//    NSMutableArray* windows = [NSMutableArray array];
//    for (NSMutableDictionary* entry in (__bridge NSArray*)visible_win_info) {
//        // Tricky...  for Google Chrome we get one hidden window for
//        // each visible window, so we need to check alpha > 0.
//        int alpha = [[entry objectForKey:(id)kCGWindowAlpha] intValue];
//        int layer = [[entry objectForKey:(id)kCGWindowLayer] intValue];
//
//        if (layer == 0 && alpha > 0) {
//            CGWindowID win_id = [[entry objectForKey:(id)kCGWindowNumber] intValue];
//
//            // some AXUIElementCreateByWindowNumber would be soooo nice.  but nope, we have to take the pain below.
//
//            int pid = [[entry objectForKey:(id)kCGWindowOwnerPID] intValue];
//            AXUIElementRef app = AXUIElementCreateApplication(pid);
//            CFArrayRef appwindows;
//            AXUIElementCopyAttributeValues(app, kAXWindowsAttribute, 0, 1000, &appwindows);
//            if (appwindows) {
//                // looks like appwindows can be NULL when this function is called during the
//                // switch-workspaces animation
//                for (id w in (__bridge NSArray*)appwindows) {
//                    AXUIElementRef win = (__bridge AXUIElementRef)w;
//                    CGWindowID tmp;
//                    _AXUIElementGetWindow(win, &tmp); //XXX: undocumented API.  but the alternative is horrifying.
//                    if (tmp == win_id) {
//                        // finally got it, insert in the result array.
//                        [windows addObject:[[PHWindow alloc] initWithElement:win]];
//                        break;
//                    }
//                }
//                CFRelease(appwindows);
//            }
//            CFRelease(app);
//        }
//    }
//    CFRelease(visible_win_info);
//
//    return windows;
//}
//