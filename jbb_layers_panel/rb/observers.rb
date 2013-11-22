
module JBB_LayersPanel

	### ENTITYOBSERVER ### ------------------------------------------------------
	#Watches for layers to be hidden or renamed (Which layers observer doesn't support)

	class JBB_LP_EntityObserver < Sketchup::EntityObserver
		def onChangeEntity(layer)
			if layer.deleted? == false
				# puts 'onchangeentity ' + layer.name
				if layer.get_attribute("jbb_layerspanel", "ID") != nil #Verify entity exists (onChangeEntity mistrigger)
					# puts layer.name
					if layer == JBB_LayersPanel.layers[0]
						layerId = 0
					else
						layerId = layer.get_attribute("jbb_layerspanel", "ID")
					end#if
					
					if layer.visible?
						showLayerFromRuby = "showLayerFromRuby('#{layerId}');"
						JBB_LayersPanel.dialog.execute_script(showLayerFromRuby)
						timer_04b = UI.start_timer(0, false) {
							UI.stop_timer(timer_04b)
							JBB_LayersPanel.unHideByGroup(layerId)
						}
					else
						hideLayerFromRuby = "hideLayerFromRuby('#{layerId}');"
						JBB_LayersPanel.dialog.execute_script(hideLayerFromRuby)
					end#if
					
					renameLayerFromRuby = "renameLayerFromRuby('#{layerId}', '#{layer.name}');"
					JBB_LayersPanel.dialog.execute_script(renameLayerFromRuby)
					
					if Sketchup.read_default("jbb_layers_panel", "auto_update") == true
						timer_04 = UI.start_timer(0, false) {
							UI.stop_timer(timer_04)
							if	JBB_LayersPanel.model.pages.selected_page != nil
								JBB_LayersPanel.model.pages.selected_page.update(32) #Update page's layers state
								# puts "update " + JBB_LayersPanel.model.pages.selected_page.name
							end#if
						}
					end#if
				end#if
			end#if
		end#def
	end#class

	@jbb_lp_entityObserver = JBB_LP_EntityObserver.new

	# Attach the observer to layer0
	@layers[0].add_observer(@jbb_lp_entityObserver)



	### LAYERSOBSERVER ### ------------------------------------------------------

	# Layers observer
	class JBB_LP_layersObserver < Sketchup::LayersObserver

		def onLayerAdded(layers, layer)
			timer_02 = UI.start_timer(0, false) {
				begin
				UI.stop_timer(timer_02)
				JBB_LayersPanel.model.start_operation("Add layer", true, true, true)
					JBB_LayersPanel.initializeLayerDictID
					JBB_LayersPanel.IdLayer(layer)
					if JBB_LayersPanel.dialog
						layerIdForJS = layer.get_attribute("jbb_layerspanel", "ID")
						addLayerFromRuby = "addLayerFromRuby('#{layer.name}', '#{layerIdForJS}');"
						JBB_LayersPanel.dialog.execute_script(addLayerFromRuby)
						showLayerFromRuby = "showLayerFromRuby('#{layerIdForJS}');"
						JBB_LayersPanel.dialog.execute_script(showLayerFromRuby)
					end#if
				JBB_LayersPanel.model.commit_operation
				JBB_LayersPanel.model.start_operation("Add layer", true, false, true)
					# puts "lo"
					layer.set_attribute("jbb_layerspanel", "observer", 1)
					layer.add_observer(JBB_LayersPanel.jbb_lp_entityObserver)
				JBB_LayersPanel.model.commit_operation
				rescue
				end
			}
		end#onLayerAdded
		
		def onLayerRemoved(layers, layer)
			layerId = layer.get_attribute("jbb_layerspanel", "ID")
			deleteLayerFromRuby = "deleteLayerFromRuby('#{layerId}');"
			JBB_LayersPanel.dialog.execute_script(deleteLayerFromRuby)
			timer_03 = UI.start_timer(0, false) {
				UI.stop_timer(timer_03)
				if JBB_LayersPanel.allowSerialize == true
					JBB_LayersPanel.dialog.execute_script("storeSerialize();")
				end#if
			}
		end#onLayerRemoved
		
		
		def onCurrentLayerChanged(layers, layer)
			if Sketchup.read_default("jbb_layers_panel", "display_warning") != false
				tool_name = Sketchup.active_model.tools.active_tool_name
				if layer != layers[0]
					if tool_name == "SketchTool" || tool_name == "RectangleTool" || tool_name == "CircleTool" || tool_name == "ArcTool" || tool_name == "PolyTool" || tool_name == "FreehandTool"
						JBB_LayersPanel.show_layerspanel_dlg_warning
					end#if
				else
					JBB_LayersPanel.close_layerspanel_dlg_warning
				end#if
			end#if
			if JBB_LayersPanel.dialog
				JBB_LayersPanel.dialog.execute_script('getActiveLayer();')
			end#if
		end#onLayerRemoved
		
	end#JBB_LP_layersObserver

	@jbb_lp_layersObserver = JBB_LP_layersObserver.new

	# Attach the observer.
	@layers.add_observer(@jbb_lp_layersObserver)



	### APPOBSERVER ### ------------------------------------------------------

	class JBB_LP_AppObserver < Sketchup::AppObserver

		def onNewModel(newModel)
			timer_05 = UI.start_timer(0, false) {
				UI.stop_timer(timer_05)
				JBB_LayersPanel.openedModel(newModel)
			}
		end#def

		def onOpenModel(newModel)
			timer_06 = UI.start_timer(0, false) {
				UI.stop_timer(timer_06)
				JBB_LayersPanel.openedModel(newModel)
			}
		end#def

	end#class

	def self.openedModel(newModel)
		@model.start_operation("Initialize Layers Panel", true)
			self.createDialog
			
			JBB_LayersPanel.model = newModel
			JBB_LayersPanel.layers = newModel.layers
			
			JBB_LayersPanel.layerDictID = nil
			
			JBB_LayersPanel.model.add_observer(@jbb_lp_modelObserver)
			JBB_LayersPanel.model.pages.add_observer(@jbb_lp_pagesObserver)
			JBB_LayersPanel.layers.add_observer(@jbb_lp_layersObserver)
			
			JBB_LayersPanel.layers.each{|layer|
				layer.remove_observer(@jbb_lp_entityObserver) #Reset observer to make sure layer is watched
				layer.add_observer(@jbb_lp_entityObserver)
				layer.set_attribute("jbb_layerspanel", "observer", 1)
			}
			
			JBB_LayersPanel.dialog.execute_script("reloadDialog();")
		@model.commit_operation
	end#def

	@jbb_lp_appObserver = JBB_LP_AppObserver.new

	# Attach the observer
	Sketchup.add_observer(@jbb_lp_appObserver)



	### MODELOBSERVER ### ------------------------------------------------------

	class JBB_LP_ModelObserver < Sketchup::ModelObserver
		def onTransactionUndo(model)
			JBB_LayersPanel.dialog.execute_script("emptyOl();")
			JBB_LayersPanel.getModelLayers(false)
			JBB_LayersPanel.getActiveLayer()
			JBB_LayersPanel.getCollapsedGroups()
		end#def
		def onTransactionRedo(model)
			JBB_LayersPanel.dialog.execute_script("emptyOl();")
			JBB_LayersPanel.getModelLayers(false)
			JBB_LayersPanel.getActiveLayer()
			JBB_LayersPanel.getCollapsedGroups()
		end#def
	end#class

	@jbb_lp_modelObserver = JBB_LP_ModelObserver.new

	# Attach the observer
	@model.add_observer(@jbb_lp_modelObserver)



	### PAGESOBSERVER ### ------------------------------------------------------

	class JBB_LP_PagesObserver < Sketchup::PagesObserver
		def onContentsModified(pages)
			activePage = JBB_LayersPanel.model.pages.selected_page
			
			if JBB_LayersPanel.check == 0 #First trigger
				JBB_LayersPanel.checkPageUpdate
				JBB_LayersPanel.check = 1
			
			else #second trigger
				JBB_LayersPanel.previousPageDict = activePage.attribute_dictionary "jbb_layerspanel_collapseGroups", true
				JBB_LayersPanel.previousPageDict2 = activePage.attribute_dictionary "jbb_layerspanel_tempHiddenGroups", true
				JBB_LayersPanel.previousPageDict3 = activePage.attribute_dictionary "jbb_layerspanel_tempHiddenByGroupLayers", true
				JBB_LayersPanel.previousPageDict4 = activePage.attribute_dictionary "jbb_layerspanel_render", true
				
				dict = activePage.attribute_dictionary "jbb_layerspanel_hiddenGroups", true
				dict2 = activePage.attribute_dictionary "jbb_layerspanel_hiddenByGroupLayers", true
				
				JBB_LayersPanel.check = 0
				
				timer_07 = UI.start_timer(0, false) {
					UI.stop_timer(timer_07)
					dict.each { | key, value |
					   activePage.set_attribute("jbb_layerspanel_tempHiddenGroups", key, value)
					}
					dict2.each { | key, value |
					   activePage.set_attribute("jbb_layerspanel_tempHiddenByGroupLayers", key, value)
					}
					JBB_LayersPanel.selectedPageLayers = activePage.layers
				
					JBB_LayersPanel.dialog.execute_script("emptyOl();")
					JBB_LayersPanel.getModelLayers(false)
					JBB_LayersPanel.getActiveLayer()
					JBB_LayersPanel.getCollapsedGroups()
				}
			end#if
		end#def
		def onElementAdded(pages, page)
			if JBB_LayersPanel.previousPageDict == nil
				dict = JBB_LayersPanel.model.attribute_dictionary "jbb_layerspanel_collapseGroups", true
			else
				dict = JBB_LayersPanel.previousPageDict
			end#if
			
			if JBB_LayersPanel.previousPageDict2 == nil
				dict2 = JBB_LayersPanel.model.attribute_dictionary "jbb_layerspanel_hiddenGroups", true
			else
				dict2 = JBB_LayersPanel.previousPageDict2
			end#if
			
			if JBB_LayersPanel.previousPageDict3 == nil
				dict3 = JBB_LayersPanel.model.attribute_dictionary "jbb_layerspanel_hiddenByGroupLayers", true
			else
				dict3 = JBB_LayersPanel.previousPageDict3
			end#if
			
			if JBB_LayersPanel.previousPageDict4 == nil
				dict4 = JBB_LayersPanel.model.attribute_dictionary "jbb_layerspanel_render", true
			else
				dict4 = JBB_LayersPanel.previousPageDict4
			end#if
			
			# puts "added " + page.name
			JBB_LayersPanel.check = 1
			
			timer_08 = UI.start_timer(0, false) {
				UI.stop_timer(timer_08)
				dict.each { | key, value |
				   page.set_attribute("jbb_layerspanel_collapseGroups", key, value)
				}
				dict2.each { | key, value |
				   page.set_attribute("jbb_layerspanel_hiddenGroups", key, value)
				}
				dict3.each { | key, value |
				   page.set_attribute("jbb_layerspanel_hiddenByGroupLayers", key, value)
				}
				dict4.each { | key, value |
				   page.set_attribute("jbb_layerspanel_render", key, value)
				}
				activePage = JBB_LayersPanel.model.pages.selected_page
				JBB_LayersPanel.model.pages.selected_page = activePage
			}
		end#def
	end#class

	def self.checkPageUpdate
		if Sketchup.read_default("jbb_layers_panel", "auto_update") == false
			activePage = Sketchup.active_model.pages.selected_page
			begin
				if @selectedPageLayers == activePage.layers
					# puts "Not updated"
				else
					# puts "Updated !"
					self.updateDictionaries(activePage)
				end#if
			rescue
			end
			
			begin
				@selectedPageLayers = activePage.layers
			rescue
			end
		end#if
	end#def

	def self.updateDictionaries(activePage)
		timer_09 = UI.start_timer(0, false) {
			UI.stop_timer(timer_09)
			dict = activePage.attribute_dictionary "jbb_layerspanel_tempHiddenGroups", true
			dict2 = activePage.attribute_dictionary "jbb_layerspanel_tempHiddenByGroupLayers", true
			
			dict.each { | key, value |
			   activePage.set_attribute("jbb_layerspanel_hiddenGroups", key, value)
			}
			dict2.each { | key, value |
			   activePage.set_attribute("jbb_layerspanel_hiddenByGroupLayers", key, value)
			}
		}
	end#def

	# Update page layers
	def self.startUpdateTimer
		begin
			@selectedPageLayers = Sketchup.active_model.pages.selected_page.layers
		rescue
		end
		
		@timerCheckUpdate = UI.start_timer(0.3, true) {
			if @check == 0
				self.checkPageUpdate
			end#if
		}
	end#def
	def self.stopUpdateTimer
		UI.stop_timer(@timerCheckUpdate)
	end#def

	if Sketchup.read_default("jbb_layers_panel", "auto_update") == false
		self.startUpdateTimer
	end#if

	@jbb_lp_pagesObserver = JBB_LP_PagesObserver.new

	# Attach the observer
	@model.pages.add_observer(@jbb_lp_pagesObserver)


end#module