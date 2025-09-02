-- ==========================================
-- MAIN CLASS DEFINITION & CONSTRUCTOR
-- ==========================================

local TowerOfHellAutofarm = {}
TowerOfHellAutofarm.__index = TowerOfHellAutofarm

function TowerOfHellAutofarm.new()
    local self = setmetatable({}, TowerOfHellAutofarm)
    
    self.player = game:GetService("Players").LocalPlayer
    self.tweenService = game:GetService("TweenService")
    self.runService = game:GetService("RunService")
    
    self.autofarmEnabled = false
    self.autofarmRunning = false
    self.currentTween = nil
    self.supportPart = nil
    self.connections = {}
    self.legitPlatforms = {}
    self.noclipConnection = nil
    self.waitingForNewTower = false
    self.roundChanged = false
    self.idleStatus = "Ready"
    self.killbrickFlag = nil
    self.originalWalkSpeed = 16
    self.originalJumpPower = 50
    self._antiAfkEnabled = false
    self._antiAfkConnection = nil
    self.newTowerDetected = false
    self.towerMonitorConnection = nil
    
    self.roundDetection = {
        skipBool = nil,
        skippedBool = nil,
        lastSectionCount = 0,
        currentRound = 1,
        towersCompleted = 0,
        lastFinishExists = false,
        roundChangeConnections = {}
    }
    
    self.config = {
        speed = 50,
        waitTime = 2,
        legitMode = false,
        retryAttempts = 3,
        touchDistance = 8,
        tweenSpeed = 2,
        safetyEnabled = true,
        killbricksDisabled = true,
        waitForNewTower = true,
        autoChat = true,
        chatDelay = 1,
        maxWaitTime = 45,
        legitPlatformSize = 4,
        legitStepDistance = 8,
        autoRestartOnRoundChange = true,
        skipDelay = 1,
        platformLifetime = 3,
        chatVariety = true,
        antiAfk = true,
        speedBoost = false,
        jumpBoost = false,
        noclipEnabled = true,
        instantTeleport = false,
        legitPartsPerSection = 5
    }
    
    self.chatMessages = {
        "Tower finished! Using Tower of Hell Autofarm - the best script available!",
        "Another tower completed with Tower of Hell Autofarm Pro!",
        "Tower of Hell Autofarm - Professional grade automation at work!",
        "Flawless tower completion with our premium autofarm script!",
        "Tower demolished! Tower of Hell Autofarm never fails!",
        "Perfect run achieved with Tower of Hell Autofarm Pro!",
        "Tower conquered! Get Tower of Hell Autofarm for yourself!",
        "Smooth sailing with the ultimate Tower of Hell automation!",
        "Tower cleared efficiently - Tower of Hell Autofarm superiority!",
        "Excellence in automation - Tower of Hell Autofarm delivers!",
        "GG EZ! Tower of Hell Autofarm makes it look effortless!",
        "Professional scripting at its finest - Tower of Hell Autofarm!",
        "Zero effort, maximum results - Tower of Hell Autofarm Pro!",
        "Another flawless victory with Tower of Hell Autofarm!",
        "Precision automation - Tower of Hell Autofarm dominance!",
        "Tower of Hell Autofarm: Making impossible towers possible!",
        "Legendary performance with Tower of Hell Autofarm technology!",
        "Tower of Hell Autofarm: Your gateway to endless victories!",
        "Crushing towers since day one - Tower of Hell Autofarm!",
        "Tower of Hell Autofarm: The ultimate climbing companion!",
        "Effortless tower completion - Tower of Hell Autofarm magic!",
        "Tower of Hell Autofarm: Redefining what's possible!",
        "Another masterpiece completion by Tower of Hell Autofarm!",
        "Tower of Hell Autofarm: Where skill meets automation!",
        "Unstoppable force meets immovable tower - Autofarm wins!",
        "Peak performance achieved with Tower of Hell Autofarm!",
        "Tower of Hell Autofarm: The gold standard of automation!",
        "Flawless execution by Tower of Hell Autofarm Pro!",
        "Tower of Hell Autofarm: Turning noobs into pros!",
        "Another day, another tower destroyed by Autofarm!"
    }
    
    self.ui = {}
    self.statusUI = nil
    
    return self
end

-- ==========================================
-- HELPER FUNCTIONS & UTILITIES
-- ==========================================

function safeGetService(serviceName)
    return pcall(function() return game:GetService(serviceName) end) and game:GetService(serviceName) or nil
end

function chatMessage(str)
    str = tostring(str)
    local TextChatService = safeGetService("TextChatService")
    local ReplicatedStorage = safeGetService("ReplicatedStorage")

    local success = pcall(function()
        if TextChatService and TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral then
            TextChatService.TextChannels.RBXGeneral:SendAsync(str)
        elseif ReplicatedStorage and ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") and ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest") then
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(str, "All")
        end
    end)

    if not success then
        pcall(function()
            if ReplicatedStorage and ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") and ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest") then
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(str, "All")
            end
        end)
    end
end

function TowerOfHellAutofarm:storeOriginalStats()
    if self.player.Character and self.player.Character:FindFirstChild("Humanoid") then
        local humanoid = self.player.Character.Humanoid
        self.originalWalkSpeed = humanoid.WalkSpeed
        self.originalJumpPower = humanoid.JumpPower
    end
end

function TowerOfHellAutofarm:showNotification(title, message, duration, notifType)
    print("[" .. title .. "] " .. message)
end

function TowerOfHellAutofarm:findInstancesWithPosition(query)
    local instances = {}
    local instanceTypes = {}
    query = query:lower()

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name:lower():find(query) then
            local position = nil
            local objType = obj.ClassName
            instanceTypes[objType] = (instanceTypes[objType] or 0) + 1

            if obj:IsA("BasePart") then
                position = obj.CFrame
            elseif obj:IsA("Model") then
                if obj.PrimaryPart then
                    position = obj.PrimaryPart.CFrame
                elseif obj:FindFirstChild("HumanoidRootPart") then
                    position = obj.HumanoidRootPart.CFrame
                end
            elseif obj:IsA("Attachment") then
                position = obj.WorldCFrame
            end

            if position then
                table.insert(instances, {obj = obj, position = position})
            end
        end
    end

    return instances, instanceTypes
end

function TowerOfHellAutofarm:findFinishGlow()
    local finishGlows, _ = self:findInstancesWithPosition("finishglow")
    
    if #finishGlows > 0 then
        return finishGlows[1]
    end
    
    local finishes, _ = self:findInstancesWithPosition("finish")
    
    for _, finishData in pairs(finishes) do
        local finish = finishData.obj
        if finish:FindFirstChild("FinishGlow") then
            local finishGlow = finish.FinishGlow
            if finishGlow:IsA("BasePart") then
                return {obj = finishGlow, position = finishGlow.CFrame}
            end
        end
    end
    
    return nil
end

function TowerOfHellAutofarm:getSections()
    local sections = {}
    
    pcall(function()
        local tower = workspace:FindFirstChild("tower")
        if tower then
            local sectionsFolder = tower:FindFirstChild("sections")
            if sectionsFolder then
                for _, section in pairs(sectionsFolder:GetChildren()) do
                    if section:IsA("Model") then
                        table.insert(sections, section)
                    end
                end
            end
        end
    end)
    
    table.sort(sections, function(a, b)
        local aStart = a:FindFirstChild("start")
        local bStart = b:FindFirstChild("start")
        
        if aStart and bStart then
            return aStart.Position.Y < bStart.Position.Y
        end
        
        local aNum = tonumber(a.Name)
        local bNum = tonumber(b.Name)
        if aNum and bNum then
            return aNum < bNum
        end
        return a.Name < b.Name
    end)
    
    return sections
end

function TowerOfHellAutofarm:safeKickProtection()
    if hookfunction then
        pcall(function()
            hookfunction(self.player.Kick, function() 
                return 
            end)
        end)
    end
end

function TowerOfHellAutofarm:createBypassTags()
    if not self.player.Character then return end
    
    local tags = {"hook", "gravity", "fusion", "jump"}
    for _, tagName in pairs(tags) do
        if not self.player.Character:FindFirstChild(tagName) then
            local tag = Instance.new("BoolValue")
            tag.Name = tagName
            tag.Value = true
            tag.Parent = self.player.Character
        end
    end
end

function TowerOfHellAutofarm:safelyDisableScripts()
    local playerScripts = self.player.PlayerScripts
    
    pcall(function()
        local localScript = playerScripts:FindFirstChild("LocalScript")
        local localScript2 = playerScripts:FindFirstChild("LocalScript2")
        
        if localScript and getconnections then
            for _, connection in pairs(getconnections(localScript.Changed)) do
                pcall(function() connection:Disable() end)
            end
        end
        
        if localScript2 and getconnections then
            for _, connection in pairs(getconnections(localScript2.Changed)) do
                pcall(function() connection:Disable() end)
            end
        end
    end)
end

function TowerOfHellAutofarm:toggleKillbricks()
    if self.config.killbricksDisabled then
        pcall(function()
            if not self.killbrickFlag then
                self.killbrickFlag = Instance.new("BoolValue")
                self.killbrickFlag.Name = "KillbrickFlag"
                self.killbrickFlag.Parent = workspace
            end
        end)
        
        pcall(function()
            local playerScripts = self.player.PlayerScripts
            local localTags = playerScripts:FindFirstChild("LocalTags")
            if localTags then
                local killBrick = localTags:FindFirstChild("KillBrick")
                if killBrick then
                    killBrick.Disabled = true
                end
            end
        end)
        
        if hookfunction then
            pcall(function()
                local humanoid = self.player.Character and self.player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    hookfunction(humanoid, "TakeDamage", function() return end)
                    local oldHealth = humanoid.Health
                    hookfunction(getmetatable(humanoid).__newindex, function(t, k, v)
                        if k == "Health" and v <= 0 then
                            return
                        end
                        return oldHealth
                    end)
                end
            end)
        end
    else
        pcall(function()
            if self.killbrickFlag then
                self.killbrickFlag:Destroy()
                self.killbrickFlag = nil
            end
        end)
        
        pcall(function()
            local playerScripts = self.player.PlayerScripts
            local localTags = playerScripts:FindFirstChild("LocalTags")
            if localTags then
                local killBrick = localTags:FindFirstChild("KillBrick")
                if killBrick then
                    killBrick.Disabled = false
                end
            end
        end)
    end
end

-- ==========================================
-- TOWER MONITORING & DETECTION
-- ==========================================

function TowerOfHellAutofarm:startTowerMonitoring()
    if self.towerMonitorConnection then
        self.towerMonitorConnection:Disconnect()
    end
    
    local lastSectionCount = #self:getSections()
    local lastFinishExists = self:findFinishGlow() ~= nil
    
    self.towerMonitorConnection = self.runService.Heartbeat:Connect(function()
        if not self.autofarmEnabled or not self.autofarmRunning then return end
        
        local currentSectionCount = #self:getSections()
        local currentFinishExists = self:findFinishGlow() ~= nil
        
        if currentSectionCount ~= lastSectionCount or currentFinishExists ~= lastFinishExists then
            if currentSectionCount > 0 then
                self.newTowerDetected = true
                self:updateStatus("Status: NEW TOWER DETECTED - Restarting immediately!")
                self:updateStatusUI(0, 0, "New tower detected - restarting")
            end
        end
        
        lastSectionCount = currentSectionCount
        lastFinishExists = currentFinishExists
    end)
end

function TowerOfHellAutofarm:stopTowerMonitoring()
    if self.towerMonitorConnection then
        self.towerMonitorConnection:Disconnect()
        self.towerMonitorConnection = nil
    end
end

function TowerOfHellAutofarm:waitForNewTowerUntilFound()
    self.waitingForNewTower = true
    local waitTime = 0
    
    self.idleStatus = "Waiting for new tower to spawn"
    self:updateIdleStatus()
    
    while self.waitingForNewTower and self.autofarmEnabled do
        local sections = self:getSections()
        local finishGlow = self:findFinishGlow()
        
        if #sections > 0 and finishGlow then
            self:updateStatus("Status: New tower found!")
            self:updateStatusUI(0, 0, "New tower found")
            self.waitingForNewTower = false
            return true
        end
        
        wait(1)
        waitTime = waitTime + 1
        self:updateStatusUI(0, 0, "Waiting for tower (" .. waitTime .. "s)")
    end
    
    return false
end

-- ==========================================
-- CORE AUTOFARM LOGIC
-- ==========================================

function TowerOfHellAutofarm:checkRoundCompleted()
    if not self.player.Character or not self.player.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local finishGlow = self:findFinishGlow()
    if finishGlow then
        local distance = (self.player.Character.HumanoidRootPart.Position - finishGlow.position.Position).Magnitude
        if distance < 15 then
            return true
        end
    end
    
    return false
end

function TowerOfHellAutofarm:setupFinishGlowDetection()
    local finishGlow = self:findFinishGlow()
    if finishGlow and finishGlow.obj then
        local connection = finishGlow.obj.Touched:Connect(function(hit)
            if hit.Parent == self.player.Character then
                spawn(function()
                    wait(2)
                    local sections = self:getSections()
                    if #sections > 0 and sections[1]:FindFirstChild("start") then
                        local startPos = sections[1].start.Position + Vector3.new(0, 3, 0)
                        self:updateStatusUI(0, 0, "Returning to start")
                        self:moveToPosition(startPos, 3)
                    end
                end)
            end
        end)
        table.insert(self.connections, connection)
    end
end

function TowerOfHellAutofarm:instantTeleport(targetPosition)
    if not self.player.Character or not self.player.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local humanoidRootPart = self.player.Character.HumanoidRootPart
    humanoidRootPart.CFrame = CFrame.new(targetPosition)
    return true
end

function TowerOfHellAutofarm:tweenToPosition(targetPosition, duration)
    if not self.player.Character or not self.player.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local humanoidRootPart = self.player.Character.HumanoidRootPart
    
    self:cleanupConnections()
    
    pcall(function()
        local humanoid = self.player.Character:FindFirstChildOfClass('Humanoid')
        if humanoid and humanoid.SeatPart then
            humanoid.Sit = false
            wait(0.1)
        end

        if self.config.safetyEnabled then
            self.supportPart = Instance.new("Part")
            self.supportPart.Name = "TweenSupportPart"
            self.supportPart.Size = Vector3.new(6, 1, 6)
            self.supportPart.Anchored = true
            self.supportPart.CanCollide = true
            self.supportPart.Transparency = 0.8
            self.supportPart.Material = Enum.Material.ForceField
            self.supportPart.Position = humanoidRootPart.Position - Vector3.new(0, 4, 0)
            self.supportPart.Parent = workspace
        end

        local lastSafeY = humanoidRootPart.Position.Y
        
        if self.config.safetyEnabled then
            local floatConnection = self.runService.Heartbeat:Connect(function()
                if self.player.Character and self.player.Character:FindFirstChild("HumanoidRootPart") then
                    local currentPos = humanoidRootPart.Position

                    if currentPos.Y < lastSafeY - 2 then
                        humanoidRootPart.CFrame = CFrame.new(currentPos.X, lastSafeY, currentPos.Z) * (humanoidRootPart.CFrame - humanoidRootPart.Position)
                        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                    else
                        lastSafeY = math.max(lastSafeY, currentPos.Y)
                    end
                end
            end)
            table.insert(self.connections, floatConnection)
        end

        local actualDuration = duration or self.config.tweenSpeed
        if self.config.legitMode then
            actualDuration = actualDuration * (1 + math.random(0, 50) / 100)
        end

        self.currentTween = self.tweenService:Create(
            humanoidRootPart,
            TweenInfo.new(actualDuration, Enum.EasingStyle.Linear),
            {CFrame = CFrame.new(targetPosition)}
        )

        if self.config.safetyEnabled and self.supportPart then
            local supportConnection = self.runService.Heartbeat:Connect(function()
                if self.player.Character and self.player.Character:FindFirstChild("HumanoidRootPart") then
                    local currentPos = humanoidRootPart.Position
                    if self.supportPart then
                        self.supportPart.Position = Vector3.new(currentPos.X, currentPos.Y - 4, currentPos.Z)
                    end
                else
                    self:cleanupConnections()
                end
            end)
            table.insert(self.connections, supportConnection)
        end

        self.currentTween:Play()
        self.currentTween.Completed:Connect(function()
            self:cleanupConnections()
        end)
    end)

    return true
end

function TowerOfHellAutofarm:moveToPosition(targetPosition, duration)
    if self.config.instantTeleport then
        return self:instantTeleport(targetPosition)
    else
        return self:tweenToPosition(targetPosition, duration)
    end
end

function TowerOfHellAutofarm:checkTouch(targetPosition, threshold)
    if not self.player.Character or not self.player.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local humanoidRootPart = self.player.Character.HumanoidRootPart
    return (humanoidRootPart.Position - targetPosition).Magnitude < (threshold or self.config.touchDistance)
end

function TowerOfHellAutofarm:enableNoclip()
    if self.noclipConnection then return end
    
    self.noclipConnection = self.runService.RenderStepped:Connect(function()
        if self.player.Character then
            for _, part in pairs(self.player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

function TowerOfHellAutofarm:disableNoclip()
    if self.noclipConnection then
        self.noclipConnection:Disconnect()
        self.noclipConnection = nil
    end
    
    if self.player.Character then
        for _, part in pairs(self.player.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end
end

function TowerOfHellAutofarm:cleanupConnections()
    for _, connection in pairs(self.connections) do
        if connection then
            connection:Disconnect()
        end
    end
    self.connections = {}
    
    if self.supportPart then
        self.supportPart:Destroy()
        self.supportPart = nil
    end
    
    if not self.config.legitMode and not self.config.noclipEnabled then
        self:disableNoclip()
    end
end

function TowerOfHellAutofarm:startAutofarm()
    if self.autofarmRunning then return end
    self.autofarmRunning = true
    self.roundChanged = false
    self.newTowerDetected = false
    
    self:startTowerMonitoring()
    
    spawn(function()
        while self.autofarmEnabled do
            if not self:waitForNewTowerUntilFound() then
                break
            end
            
            self.newTowerDetected = false
            
            while self.autofarmEnabled and not self.newTowerDetected and not self.roundChanged do
                local sections = self:getSections()
                
                if #sections == 0 then
                    self.idleStatus = "No tower found"
                    self:updateIdleStatus()
                    break
                end
                
                self:setupFinishGlowDetection()
                local completedSections = 0
                
                for i, section in pairs(sections) do
                    if not self.autofarmEnabled or self.roundChanged or self.newTowerDetected then break end
                    
                    if self.config.legitMode then
                        if self:processLegitSection(section, completedSections, #sections) then
                            completedSections = completedSections + 1
                        else
                            break
                        end
                    else
                        self:updateStatus("Status: Moving to " .. section.Name)
                        self:updateStatusUI(completedSections, #sections, "Moving to " .. section.Name)
                        
                        local startPart = section:FindFirstChild("start")
                        if startPart and startPart:IsA("BasePart") then
                            local targetPos = startPart.Position + Vector3.new(0, 3, 0)
                            
                            local maxAttempts = self.config.retryAttempts
                            local attempts = 0
                            local reached = false
                            
                            while attempts < maxAttempts and not reached and self.autofarmEnabled and not self.roundChanged and not self.newTowerDetected do
                                attempts = attempts + 1
                                
                                self:moveToPosition(targetPos, nil)
                                if self.currentTween and not self.config.instantTeleport then
                                    local completed = false
                                    local connection = self.currentTween.Completed:Connect(function()
                                        completed = true
                                    end)
                                    
                                    while not completed and not self.newTowerDetected and self.autofarmEnabled do
                                        wait(0.1)
                                    end
                                    
                                    connection:Disconnect()
                                    
                                    if self.newTowerDetected then
                                        if self.currentTween then
                                            self.currentTween:Cancel()
                                        end
                                        break
                                    end
                                end
                                
                                if self.newTowerDetected then break end
                                
                                reached = self:checkTouch(targetPos, self.config.touchDistance)
                                
                                if reached then
                                    completedSections = completedSections + 1
                                    self:updateStatus("Status: Reached " .. section.Name)
                                    self:updateStatusUI(completedSections, #sections, "Reached " .. section.Name)
                                    wait(self.config.waitTime)
                                else
                                    self:updateStatus("Status: Retrying " .. section.Name .. " (" .. attempts .. "/" .. maxAttempts .. ")")
                                    self:updateStatusUI(completedSections, #sections, "Retrying " .. section.Name)
                                    wait(0.5)
                                end
                            end
                            
                            if not reached and not self.roundChanged and not self.newTowerDetected then
                                self:updateStatus("Status: Failed to reach " .. section.Name)
                                self:updateStatusUI(completedSections, #sections, "Failed " .. section.Name)
                                wait(1)
                            end
                        end
                    end
                    
                    if self.newTowerDetected then break end
                end
                
                if self.newTowerDetected then break end
                
                if self.autofarmEnabled and not self.roundChanged then
                    self:updateStatus("Status: Looking for finish")
                    self:updateStatusUI(completedSections, #sections, "Looking for finish")
                    
                    local finishGlow = self:findFinishGlow()
                    
                    if finishGlow then
                        local targetPos = finishGlow.position.Position + Vector3.new(0, 2, 0)
                        
                        local maxAttempts = self.config.retryAttempts
                        local attempts = 0
                        local reached = false
                        
                        while attempts < maxAttempts and not reached and self.autofarmEnabled and not self.roundChanged and not self.newTowerDetected do
                            attempts = attempts + 1
                            self:updateStatus("Status: Going to " .. finishGlow.obj.Name)
                            self:updateStatusUI(completedSections, #sections, "Going to finish")
                            
                            self:moveToPosition(targetPos, 3)
                            if self.currentTween and not self.config.instantTeleport then
                                local completed = false
                                local connection = self.currentTween.Completed:Connect(function()
                                    completed = true
                                end)
                                
                                while not completed and not self.newTowerDetected and self.autofarmEnabled do
                                    wait(0.1)
                                end
                                
                                connection:Disconnect()
                                
                                if self.newTowerDetected then
                                    if self.currentTween then
                                        self.currentTween:Cancel()
                                    end
                                    break
                                end
                            end
                            
                            if self.newTowerDetected then break end
                            
                            reached = self:checkTouch(targetPos, self.config.touchDistance)
                            
                            if reached then
                                self.roundDetection.towersCompleted = self.roundDetection.towersCompleted + 1
                                self:updateStatus("Status: Tower Completed!")
                                self:updateStatusUI(completedSections, #sections, "Tower Completed!")
                                
                                wait(self.config.skipDelay)
                                chatMessage("/skip")
                                wait(self.config.chatDelay)
                                
                                if self.config.autoChat then
                                    local message
                                    if self.config.chatVariety then
                                        message = self.chatMessages[math.random(1, #self.chatMessages)]
                                    else
                                        message = "Tower finished! Using Tower of Hell Autofarm - professional automation!"
                                    end
                                    chatMessage(message)
                                end
                                
                                break
                            else
                                self:updateStatus("Status: Retrying finish (" .. attempts .. "/" .. maxAttempts .. ")")
                                self:updateStatusUI(completedSections, #sections, "Retrying finish")
                                wait(0.5)
                            end
                        end
                    else
                        self:updateStatus("Status: No finish found")
                        self:updateStatusUI(completedSections, #sections, "No finish found")
                        wait(2)
                    end
                end
                
                if not self.newTowerDetected then
                    break
                end
            end
            
            if self.newTowerDetected then
                self:updateStatus("Status: Restarting due to new tower detection...")
                self:updateStatusUI(0, 0, "Restarting for new tower")
                self:cleanupConnections()
                self:cleanupLegitPlatforms()
                wait(1)
            end
        end
        
        self:stopTowerMonitoring()
        self:cleanupConnections()
        self:cleanupLegitPlatforms()
        self.autofarmRunning = false
        self.idleStatus = "Stopped"
        self:updateIdleStatus()
    end)
end

function TowerOfHellAutofarm:waitForNewTowerAfterCompletion()
    if not self.config.waitForNewTower then return true end
    
    self.waitingForNewTower = true
    local waitTime = 0
    
    self.idleStatus = "Waiting for tower skip/new tower"
    self:updateIdleStatus()
    
    while waitTime < self.config.maxWaitTime and self.waitingForNewTower and not self.roundChanged do
        if self:checkForNewTower() then
            self:updateStatus("Status: New tower detected!")
            self:updateStatusUI(0, 0, "New tower detected")
            self.waitingForNewTower = false
            return true
        end
        
        wait(1)
        waitTime = waitTime + 1
        self:updateStatusUI(0, 0, "Waiting (" .. (self.config.maxWaitTime - waitTime) .. "s)")
    end
    
    self.waitingForNewTower = false
    return waitTime < self.config.maxWaitTime or self.roundChanged
end

-- ==========================================
-- LEGIT MODE FUNCTIONS
-- ==========================================

function TowerOfHellAutofarm:createLegitPlatform(position)
    local platform = Instance.new("Part")
    platform.Name = "LegitPlatform"
    platform.Size = Vector3.new(self.config.legitPlatformSize, 0.5, self.config.legitPlatformSize)
    platform.Position = position
    platform.Anchored = true
    platform.CanCollide = true
    platform.Transparency = 0.5
    platform.Material = Enum.Material.Neon
    platform.BrickColor = BrickColor.new("Bright green")
    platform.Parent = workspace
    
    table.insert(self.legitPlatforms, platform)
    
    spawn(function()
        wait(self.config.platformLifetime)
        if platform and platform.Parent then
            platform:Destroy()
        end
    end)
    
    return platform
end

function TowerOfHellAutofarm:cleanupLegitPlatforms()
    for _, platform in pairs(self.legitPlatforms) do
        if platform and platform.Parent then
            platform:Destroy()
        end
    end
    self.legitPlatforms = {}
end

function TowerOfHellAutofarm:processLegitSection(section, completedSections, totalSections)
    self:updateStatus("Status: Legit mode - Processing " .. section.Name)
    self:updateStatusUI(completedSections, totalSections, "Legit: Processing " .. section.Name)
    
    local startPart = section:FindFirstChild("start")
    if startPart and startPart:IsA("BasePart") then
        local startPos = startPart.Position + Vector3.new(0, 3, 0)
        self:moveToPosition(startPos, nil)
        if self.currentTween and not self.config.instantTeleport then
            local completed = false
            local connection = self.currentTween.Completed:Connect(function()
                completed = true
            end)
            
            while not completed and not self.newTowerDetected and self.autofarmEnabled do
                wait(0.1)
            end
            
            connection:Disconnect()
            
            if self.newTowerDetected then
                if self.currentTween then
                    self.currentTween:Cancel()
                end
                return false
            end
        end
        
        if self.newTowerDetected then return false end
        wait(self.config.waitTime / 2)
    end
    
    local parts = {}
    for _, part in pairs(section:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "start" and part.CanCollide and part.Size.Magnitude > 2 then
            table.insert(parts, part)
        end
    end
    
    table.sort(parts, function(a, b)
        return a.Position.Y < b.Position.Y
    end)
    
    local partsToVisit = math.min(#parts, self.config.legitPartsPerSection)
    
    for i = 1, partsToVisit do
        if not self.autofarmEnabled or self.roundChanged or self.newTowerDetected then break end
        
        local part = parts[i]
        local targetPos = part.Position + Vector3.new(
            math.random(-2, 2),
            4,
            math.random(-2, 2)
        )
        
        self:updateStatusUI(completedSections, totalSections, "Legit: Part " .. i .. "/" .. partsToVisit)
        
        self:moveToPosition(targetPos, nil)
        if self.currentTween and not self.config.instantTeleport then
            local completed = false
            local connection = self.currentTween.Completed:Connect(function()
                completed = true
            end)
            
            while not completed and not self.newTowerDetected and self.autofarmEnabled do
                wait(0.1)
            end
            
            connection:Disconnect()
            
            if self.newTowerDetected then
                if self.currentTween then
                    self.currentTween:Cancel()
                end
                return false
            end
        end
        
        if self.newTowerDetected then return false end
        wait(0.3 + math.random(0, 7) / 10)
    end
    
    return true
end

-- ==========================================
-- ROUND DETECTION & MANAGEMENT
-- ==========================================

function TowerOfHellAutofarm:resetAutofarmState()
    self.waitingForNewTower = false
    self.roundChanged = true
    self.roundDetection.lastSectionCount = 0
    self.roundDetection.lastFinishExists = false
    
    self:cleanupConnections()
    self:cleanupLegitPlatforms()
    
    if self.currentTween then
        self.currentTween:Cancel()
        self.currentTween = nil
    end
end

function TowerOfHellAutofarm:setupRoundDetection()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    
    for _, connection in pairs(self.roundDetection.roundChangeConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    self.roundDetection.roundChangeConnections = {}
    
    pcall(function()
        for _, obj in pairs(replicatedStorage:GetDescendants()) do
            if obj:IsA("BoolValue") then
                if obj.Name:lower():find("skip") and not self.roundDetection.skipBool then
                    self.roundDetection.skipBool = obj
                    local connection = obj.Changed:Connect(function()
                        self:onRoundChange("Skip bool changed")
                    end)
                    table.insert(self.roundDetection.roundChangeConnections, connection)
                elseif obj.Name:lower():find("skipped") and not self.roundDetection.skippedBool then
                    self.roundDetection.skippedBool = obj
                    local connection = obj.Changed:Connect(function()
                        self:onRoundChange("Skipped bool changed")
                    end)
                    table.insert(self.roundDetection.roundChangeConnections, connection)
                end
            end
        end
    end)
end

function TowerOfHellAutofarm:onRoundChange(reason)
    if not self.config.autoRestartOnRoundChange then return end
    
    self.roundDetection.currentRound = self.roundDetection.currentRound + 1
    
    spawn(function()
        self:resetAutofarmState()
        
        wait(2)
        
        self:updateStatus("Status: Round changed - " .. reason)
        self:updateStatusUI(0, 0, "Round changed")
        
        if self.autofarmEnabled then
            wait(1)
            self:updateStatus("Status: Restarting autofarm after round change...")
            self:restartAutofarm()
        end
    end)
end

function TowerOfHellAutofarm:restartAutofarm()
    if not self.autofarmEnabled then return end
    
    self.autofarmRunning = false
    self.roundChanged = false
    
    wait(0.5)
    
    if self.autofarmEnabled then
        self:startAutofarm()
    end
end

function TowerOfHellAutofarm:checkForNewTower()
    local sections = self:getSections()
    local currentSectionCount = #sections
    local finishExists = self:findFinishGlow() ~= nil
    
    if currentSectionCount ~= self.roundDetection.lastSectionCount or 
       finishExists ~= self.roundDetection.lastFinishExists then
        self.roundDetection.lastSectionCount = currentSectionCount
        self.roundDetection.lastFinishExists = finishExists
        return currentSectionCount > 0
    end
    
    return false
end

-- ==========================================
-- CONFIG MANAGEMENT (SAVE/LOAD)
-- ==========================================

function TowerOfHellAutofarm:saveConfig()
    if not isfolder or not writefile then return false end
    
    if not isfolder("TowerOfHellAutofarm") then
        makefolder("TowerOfHellAutofarm")
    end
    
    local HttpService = game:GetService("HttpService")
    local configData = HttpService:JSONEncode(self.config)
    
    pcall(function()
        writefile("TowerOfHellAutofarm/config.json", configData)
    end)
    
    return true
end

function TowerOfHellAutofarm:loadConfig()
    if not isfolder or not readfile or not isfile then return false end
    
    if not isfolder("TowerOfHellAutofarm") or not isfile("TowerOfHellAutofarm/config.json") then
        return false
    end
    
    local success, configData = pcall(function()
        return readfile("TowerOfHellAutofarm/config.json")
    end)
    
    if success then
        local HttpService = game:GetService("HttpService")
        local success2, config = pcall(function()
            return HttpService:JSONDecode(configData)
        end)
        
        if success2 then
            for key, value in pairs(config) do
                if self.config[key] ~= nil then
                    self.config[key] = value
                end
            end
            return true
        end
    end
    
    return false
end

function TowerOfHellAutofarm:autoSaveConfig()
    spawn(function()
        while true do
            wait(30)
            self:saveConfig()
        end
    end)
end

function TowerOfHellAutofarm:exportConfig()
    local config = {}
    for key, value in pairs(self.config) do
        config[key] = value
    end
    
    local HttpService = game:GetService("HttpService")
    local jsonString = HttpService:JSONEncode(config)
    
    if setclipboard then
        setclipboard(jsonString)
        return "Config copied to clipboard!"
    else
        return jsonString
    end
end

function TowerOfHellAutofarm:importConfig(jsonString)
    local HttpService = game:GetService("HttpService")
    local success, config = pcall(function()
        return HttpService:JSONDecode(jsonString)
    end)
    
    if not success then
        return false, "Invalid JSON format"
    end
    
    for key, value in pairs(config) do
        if self.config[key] ~= nil then
            self.config[key] = value
        end
    end
    
    self:saveConfig()
    return true, "Config imported successfully!"
end

-- ==========================================
-- UI MANAGEMENT
-- ==========================================

function TowerOfHellAutofarm:createStatusUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TowerAutofarmStatus"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = self.player.PlayerGui
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0, 500, 0, 100)
    statusLabel.Position = UDim2.new(0.5, -250, 1, -120)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Tower of Hell Autofarm\nRound: 1 | Section: 0/0 | Towers: 0 | Status: Ready"
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.TextSize = 16
    statusLabel.Font = Enum.Font.RobotoMono
    statusLabel.TextStrokeTransparency = 0
    statusLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    statusLabel.Parent = screenGui
    
    self.statusUI = statusLabel
end

function TowerOfHellAutofarm:updateStatusUI(section, total, status)
    if self.statusUI then
        local roundText = "Round: " .. self.roundDetection.currentRound
        local sectionText = "Section: " .. (section or 0) .. "/" .. (total or 0)
        local towerText = "Towers: " .. self.roundDetection.towersCompleted
        local statusText = "Status: " .. (status or "Ready")
        local modeText = self.config.legitMode and " [LEGIT]" or " [SPEED]"
        local noclipText = self.config.noclipEnabled and " [NOCLIP]" or ""
        local instantText = self.config.instantTeleport and " [INSTANT]" or ""
        local killbrickText = self.config.killbricksDisabled and " [GODMODE]" or ""
        
        self.statusUI.Text = "Tower of Hell Autofarm" .. modeText .. noclipText .. instantText .. killbrickText .. "\n" .. roundText .. " | " .. sectionText .. " | " .. towerText .. " | " .. statusText
    end
end

function TowerOfHellAutofarm:updateIdleStatus()
    if not self.autofarmEnabled then
        self:updateStatusUI(0, 0, "Idle - " .. self.idleStatus)
    elseif self.waitingForNewTower then
        self:updateStatusUI(0, 0, "Idle - " .. self.idleStatus)
    elseif not self.autofarmRunning then
        self:updateStatusUI(0, 0, "Idle - Ready to start")
    end
end

function TowerOfHellAutofarm:updateStatus(text)
    if self.ui.statusLabel then
        pcall(function()
            self.ui.statusLabel:SetText(text)
        end)
    end
end

function TowerOfHellAutofarm:updateProgress(text)
    if self.ui.progressLabel then
        pcall(function()
            self.ui.progressLabel:SetText(text)
        end)
    end
end

-- ==========================================
-- USEFUL FEATURES
-- ==========================================

function TowerOfHellAutofarm:toggleAntiAfk()
    local LocalPlayer = self.player
    if self._antiAfkEnabled then
        self._antiAfkEnabled = false
        if self._antiAfkConnection then
            self._antiAfkConnection:Disconnect()
            self._antiAfkConnection = nil
        end
        self:showNotification("Success", "Disabled anti-AFK", 2, "success")
    else
        self._antiAfkEnabled = true

        local GC = getconnections 

        if GC then
            local success, error = pcall(function()
                for _, v in pairs(GC(LocalPlayer.Idled)) do
                    if v["Disable"] then
                        v["Disable"](v)
                    elseif v["Disconnect"] then
                        v["Disconnect"](v)
                    end
                end
            end)

            if success then
                self:showNotification("Success", "Enabled anti-AFK (advanced method)", 2, "success")
            else
                self:showNotification("Warning", "Advanced method failed, using fallback", 2, "warning")
                local VirtualUser = game:GetService("VirtualUser")
                self._antiAfkConnection = LocalPlayer.Idled:Connect(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
                self:showNotification("Success", "Enabled anti-AFK (fallback method)", 2, "success")
            end
        else
            local VirtualUser = game:GetService("VirtualUser")
            self._antiAfkConnection = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            self:showNotification("Success", "Enabled anti-AFK (fallback method)", 2, "success")
        end
    end
end

function TowerOfHellAutofarm:setupAntiAfk()
    if self.config.antiAfk and not self._antiAfkEnabled then
        self:toggleAntiAfk()
    elseif not self.config.antiAfk and self._antiAfkEnabled then
        self:toggleAntiAfk()
    end
end

function TowerOfHellAutofarm:applySpeedBoost()
    if self.player.Character and self.player.Character:FindFirstChild("Humanoid") then
        local humanoid = self.player.Character.Humanoid
        if self.config.speedBoost then
            humanoid.WalkSpeed = 50
        else
            humanoid.WalkSpeed = self.originalWalkSpeed
        end
    end
end

function TowerOfHellAutofarm:applyJumpBoost()
    if self.player.Character and self.player.Character:FindFirstChild("Humanoid") then
        local humanoid = self.player.Character.Humanoid
        if self.config.jumpBoost then
            humanoid.JumpPower = 100
        else
            humanoid.JumpPower = self.originalJumpPower
        end
    end
end

-- ==========================================
-- GUI CREATION
-- ==========================================

function TowerOfHellAutofarm:createGUI()
    local success, Library = pcall(function()
        return loadstring(
            game:HttpGetAsync("https://raw.githubusercontent.com/focat69/gamesense/refs/heads/main/source?t=" .. tostring(tick()))
        )()
    end)
    
    if not success then
        warn("Failed to load UI library")
        return
    end

    local Window = Library:New({
        Name = "Tower of Hell Autofarm v9.0",
        Padding = 5
    })

    local AutofarmTab = Window:CreateTab({Name = "Autofarm"})
    local ConfigTab = Window:CreateTab({Name = "Config & Legit"})
    local UtilityTab = Window:CreateTab({Name = "Utility & Features"})
    local InfoTab = Window:CreateTab({Name = "Info"})

    self.ui.startButton = AutofarmTab:Button({
        Name = "Start Autofarm",
        Callback = function()
            self.autofarmEnabled = not self.autofarmEnabled
            
            if self.autofarmEnabled then
                if self.ui.startButton then
                    self.ui.startButton:SetText("Stop Autofarm")
                end
                self:startAutofarm()
            else
                if self.ui.startButton then
                    self.ui.startButton:SetText("Start Autofarm")
                end
                self.autofarmRunning = false
                self:stopTowerMonitoring()
                self:cleanupConnections()
                self:cleanupLegitPlatforms()
                if self.currentTween then
                    self.currentTween:Cancel()
                end
                self.idleStatus = "Stopped"
                self:updateIdleStatus()
            end
        end
    })

    self.ui.statusLabel = AutofarmTab:Label({Message = "Status: Ready"})

    AutofarmTab:Button({
        Name = "Skip Current Section",
        Callback = function()
            if self.currentTween then
                self.currentTween:Cancel()
            end
            Library:Notify({Description = "Skipped current section", Duration = 2})
        end
    })

    AutofarmTab:Button({
        Name = "Complete Current Tower",
        Callback = function()
            if self.autofarmRunning then
                spawn(function()
                    local finishGlow = self:findFinishGlow()
                    if finishGlow then
                        local targetPos = finishGlow.position.Position + Vector3.new(0, 2, 0)
                        self:moveToPosition(targetPos, 3)
                    end
                end)
            end
        end
    })

    AutofarmTab:Button({
        Name = "Force Restart Autofarm",
        Callback = function()
            if self.autofarmEnabled then
                self:restartAutofarm()
                Library:Notify({Description = "Autofarm restarted!", Duration = 2})
            end
        end
    })

    local speedSlider = ConfigTab:Slider({
        Name = "Movement Speed", Min = 20, Max = 100, Default = self.config.speed, Step = 5,
        Callback = function(value) self.config.speed = value; self:saveConfig() end
    })

    local waitSlider = ConfigTab:Slider({
        Name = "Wait Time", Min = 1, Max = 10, Default = self.config.waitTime, Step = 1,
        Callback = function(value) self.config.waitTime = value; self:saveConfig() end
    })

    local tweenSpeedSlider = ConfigTab:Slider({
        Name = "Tween Speed", Min = 1, Max = 10, Default = self.config.tweenSpeed, Step = 1,
        Callback = function(value) self.config.tweenSpeed = value; self:saveConfig() end
    })

    local touchSlider = ConfigTab:Slider({
        Name = "Touch Distance", Min = 5, Max = 15, Default = self.config.touchDistance, Step = 1,
        Callback = function(value) self.config.touchDistance = value; self:saveConfig() end
    })

    local retrySlider = ConfigTab:Slider({
        Name = "Retry Attempts", Min = 1, Max = 5, Default = self.config.retryAttempts, Step = 1,
        Callback = function(value) self.config.retryAttempts = value; self:saveConfig() end
    })

    local chatDelaySlider = ConfigTab:Slider({
        Name = "Chat Delay", Min = 1, Max = 10, Default = self.config.chatDelay, Step = 1,
        Callback = function(value) self.config.chatDelay = value; self:saveConfig() end
    })

    local skipDelaySlider = ConfigTab:Slider({
        Name = "Skip Delay", Min = 0, Max = 5, Default = self.config.skipDelay, Step = 1,
        Callback = function(value) self.config.skipDelay = value; self:saveConfig() end
    })

    local platformSizeSlider = ConfigTab:Slider({
        Name = "Platform Size (Legit)", Min = 2, Max = 8, Default = self.config.legitPlatformSize, Step = 1,
        Callback = function(value) self.config.legitPlatformSize = value; self:saveConfig() end
    })

    local stepDistanceSlider = ConfigTab:Slider({
        Name = "Step Distance (Legit)", Min = 4, Max = 16, Default = self.config.legitStepDistance, Step = 1,
        Callback = function(value) self.config.legitStepDistance = value; self:saveConfig() end
    })

    local platformLifetimeSlider = ConfigTab:Slider({
        Name = "Platform Lifetime (Legit)", Min = 1, Max = 10, Default = self.config.platformLifetime, Step = 1,
        Callback = function(value) self.config.platformLifetime = value; self:saveConfig() end
    })

    local legitPartsSlider = ConfigTab:Slider({
        Name = "Parts Per Section (Legit)", Min = 3, Max = 15, Default = self.config.legitPartsPerSection, Step = 1,
        Callback = function(value) self.config.legitPartsPerSection = value; self:saveConfig() end
    })

    local legitToggle = ConfigTab:Toggle({
        Name = "Legit Mode", State = self.config.legitMode,
        Callback = function(state)
            self.config.legitMode = state
            if state then self:enableNoclip() else 
                if not self.config.noclipEnabled then
                    self:disableNoclip()
                end
                self:cleanupLegitPlatforms() 
            end
            self:saveConfig()
        end
    })

    local noclipToggle = ConfigTab:Toggle({
        Name = "Noclip Enabled", State = self.config.noclipEnabled,
        Callback = function(state) 
            self.config.noclipEnabled = state
            if state then 
                self:enableNoclip() 
            else 
                if not self.config.legitMode then
                    self:disableNoclip()
                end
            end
            self:saveConfig()
        end
    })

    local instantToggle = ConfigTab:Toggle({
        Name = "Instant Teleport", State = self.config.instantTeleport,
        Callback = function(state) 
            self.config.instantTeleport = state
            self:saveConfig()
        end
    })

    local safetyToggle = ConfigTab:Toggle({
        Name = "Safety Platform", State = self.config.safetyEnabled,
        Callback = function(state) self.config.safetyEnabled = state; self:saveConfig() end
    })

    local autoRestartToggle = ConfigTab:Toggle({
        Name = "Auto Restart on Round Change", State = self.config.autoRestartOnRoundChange,
        Callback = function(state) self.config.autoRestartOnRoundChange = state; self:saveConfig() end
    })

    local killbricksToggle = UtilityTab:Toggle({
        Name = "Disable Killbricks (Godmode)", State = self.config.killbricksDisabled,
        Callback = function(state) 
            self.config.killbricksDisabled = state
            self:toggleKillbricks()
            self:saveConfig()
        end
    })

    local waitTowerToggle = UtilityTab:Toggle({
        Name = "Wait For New Tower", State = self.config.waitForNewTower,
        Callback = function(state) self.config.waitForNewTower = state; self:saveConfig() end
    })

    local autoChatToggle = UtilityTab:Toggle({
        Name = "Auto Chat Messages", State = self.config.autoChat,
        Callback = function(state) self.config.autoChat = state; self:saveConfig() end
    })

    local chatVarietyToggle = UtilityTab:Toggle({
        Name = "Chat Message Variety", State = self.config.chatVariety,
        Callback = function(state) self.config.chatVariety = state; self:saveConfig() end
    })

    local antiAfkToggle = UtilityTab:Toggle({
        Name = "Anti-AFK", State = self.config.antiAfk,
        Callback = function(state) 
            self.config.antiAfk = state
            self:setupAntiAfk()
            self:saveConfig()
        end
    })

    local speedBoostToggle = UtilityTab:Toggle({
        Name = "Speed Boost", State = self.config.speedBoost,
        Callback = function(state) 
            self.config.speedBoost = state
            self:applySpeedBoost()
            self:saveConfig()
        end
    })

    local jumpBoostToggle = UtilityTab:Toggle({
        Name = "Jump Boost", State = self.config.jumpBoost,
        Callback = function(state) 
            self.config.jumpBoost = state
            self:applyJumpBoost()
            self:saveConfig()
        end
    })

    UtilityTab:Button({
        Name = "Clear All Platforms (Legit)",
        Callback = function()
            self:cleanupLegitPlatforms()
            Library:Notify({Description = "All platforms cleared!", Duration = 2})
        end
    })

    UtilityTab:Button({
        Name = "Toggle Noclip Manual",
        Callback = function()
            if self.noclipConnection then
                self:disableNoclip()
                Library:Notify({Description = "Noclip disabled", Duration = 2})
            else
                self:enableNoclip()
                Library:Notify({Description = "Noclip enabled", Duration = 2})
            end
        end
    })

    UtilityTab:Button({
        Name = "Reset Round Counter",
        Callback = function()
            self.roundDetection.currentRound = 1
            self.roundDetection.towersCompleted = 0
            self:updateStatusUI(0, 0, "Reset")
            Library:Notify({Description = "Round counter reset!", Duration = 2})
        end
    })

    UtilityTab:Button({
        Name = "Force Round Detection",
        Callback = function()
            self:onRoundChange("Manual trigger")
            Library:Notify({Description = "Round detection triggered!", Duration = 2})
        end
    })

    UtilityTab:Button({
        Name = "Export Config",
        Callback = function()
            local result = self:exportConfig()
            Library:Notify({Description = result, Duration = 3})
        end
    })

    local importTextbox = UtilityTab:Textbox({
        Placeholder = "Paste config JSON here...",
        Callback = function(text)
            if text and text ~= "" then
                local success, message = self:importConfig(text)
                Library:Notify({Description = message, Duration = 3})
                if success then
                    speedSlider:SetValue(self.config.speed)
                    waitSlider:SetValue(self.config.waitTime)
                    tweenSpeedSlider:SetValue(self.config.tweenSpeed)
                    touchSlider:SetValue(self.config.touchDistance)
                    retrySlider:SetValue(self.config.retryAttempts)
                    chatDelaySlider:SetValue(self.config.chatDelay)
                    skipDelaySlider:SetValue(self.config.skipDelay)
                    platformSizeSlider:SetValue(self.config.legitPlatformSize)
                    stepDistanceSlider:SetValue(self.config.legitStepDistance)
                    platformLifetimeSlider:SetValue(self.config.platformLifetime)
                    legitPartsSlider:SetValue(self.config.legitPartsPerSection)
                    legitToggle:SetValue(self.config.legitMode)
                    noclipToggle:SetValue(self.config.noclipEnabled)
                    instantToggle:SetValue(self.config.instantTeleport)
                    safetyToggle:SetValue(self.config.safetyEnabled)
                    autoRestartToggle:SetValue(self.config.autoRestartOnRoundChange)
                    killbricksToggle:SetValue(self.config.killbricksDisabled)
                    waitTowerToggle:SetValue(self.config.waitForNewTower)
                    autoChatToggle:SetValue(self.config.autoChat)
                    chatVarietyToggle:SetValue(self.config.chatVariety)
                    antiAfkToggle:SetValue(self.config.antiAfk)
                    speedBoostToggle:SetValue(self.config.speedBoost)
                    jumpBoostToggle:SetValue(self.config.jumpBoost)
                end
            end
        end
    })

    UtilityTab:Button({
        Name = "Teleport to Start",
        Callback = function()
            local sections = self:getSections()
            if #sections > 0 and sections[1]:FindFirstChild("start") then
                local startPos = sections[1].start.Position + Vector3.new(0, 3, 0)
                self:moveToPosition(startPos, 2)
            end
        end
    })

    UtilityTab:Button({
        Name = "Teleport to Finish",
        Callback = function()
            local finishGlow = self:findFinishGlow()
            if finishGlow then
                local finishPos = finishGlow.position.Position + Vector3.new(0, 2, 0)
                self:moveToPosition(finishPos, 3)
                Library:Notify({Description = "Found and teleporting to " .. finishGlow.obj.Name, Duration = 2})
            else
                Library:Notify({Description = "No finish found!", Duration = 2})
            end
        end
    })

    UtilityTab:Button({
        Name = "Emergency Stop",
        Callback = function()
            self.autofarmEnabled = false
            self.autofarmRunning = false
            self.waitingForNewTower = false
            self:stopTowerMonitoring()
            self:cleanupConnections()
            self:cleanupLegitPlatforms()
            if self.currentTween then
                self.currentTween:Cancel()
            end
            self.idleStatus = "Emergency Stopped"
            self:updateIdleStatus()
            Library:Notify({Description = "Emergency stop activated!", Duration = 2})
        end
    })

    InfoTab:Label({Message = "Tower of Hell Autofarm v9.0"})
    InfoTab:Label({Message = "Perfect autofarm with intelligent tower detection"})

    InfoTab:Button({
        Name = "Check Round Detection",
        Callback = function()
            local skipFound = self.roundDetection.skipBool and "Found" or "Not found"
            local skippedFound = self.roundDetection.skippedBool and "Found" or "Not found"
            Library:Notify({Description = "Skip bool: " .. skipFound .. " | Skipped bool: " .. skippedFound, Duration = 4})
        end
    })

    InfoTab:Button({
        Name = "Check Tower Status",
        Callback = function()
            local sections = self:getSections()
            local finishGlow = self:findFinishGlow()
            Library:Notify({Description = "Sections: " .. #sections .. " | Finish: " .. (finishGlow and "Yes" or "No"), Duration = 3})
        end
    })

    InfoTab:Label({Message = "Player: " .. self.player.Name})

    InfoTab:Button({
        Name = "Destroy UI",
        Callback = function()
            Window:Destroy()
            if self.statusUI then
                self.statusUI.Parent:Destroy()
            end
        end
    })

    Library:Notify({Description = "Tower of Hell Autofarm loaded successfully!", Duration = 3})
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

function TowerOfHellAutofarm:initialize()
    self:storeOriginalStats()
    self:safeKickProtection()
    
    if self.player.Character then
        self:createBypassTags()
    end
    
    self.player.CharacterAdded:Connect(function()
        wait(1)
        self:storeOriginalStats()
        self:createBypassTags()
        self:applySpeedBoost()
        self:applyJumpBoost()
        self:toggleKillbricks()
        if self.config.noclipEnabled then
            self:enableNoclip()
        end
    end)
    
    self:safelyDisableScripts()
    self:setupRoundDetection()
    self:createStatusUI()
    self:loadConfig()
    self:autoSaveConfig()
    self:setupAntiAfk()
    self:toggleKillbricks()
    
    if self.config.noclipEnabled then
        self:enableNoclip()
    end
    
    self:createGUI()
    
    spawn(function()
        while true do
            wait(2)
            self:createBypassTags()
            if self.config.killbricksDisabled then
                self:toggleKillbricks()
            end
        end
    end)
    
    spawn(function()
        while true do
            wait(10)
            if not self.roundDetection.skipBool and not self.roundDetection.skippedBool then
                self:setupRoundDetection()
            end
        end
    end)
    
    spawn(function()
        while true do
            wait(1)
            if not self.autofarmRunning and not self.waitingForNewTower then
                self:updateIdleStatus()
            end
        end
    end)
end

local autofarm = TowerOfHellAutofarm.new()
autofarm:initialize()
