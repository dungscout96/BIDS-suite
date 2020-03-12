import javafx.application.Application
import javafx.application.Platform
import javafx.beans.property.SimpleStringProperty
import javafx.collections.FXCollections
import javafx.collections.ListChangeListener
import javafx.collections.ObservableList
import javafx.embed.swing.JFXPanel
import javafx.event.EventHandler
import javafx.geometry.Insets
import javafx.geometry.Pos
import javafx.scene.Parent
import javafx.scene.control.*
import javafx.scene.layout.BorderPane
import javafx.scene.layout.GridPane
import javafx.scene.layout.VBox
import javafx.scene.text.Font
import javafx.scene.text.FontWeight
import javafx.scene.text.TextAlignment
import javafx.stage.Stage
import javafx.stage.StageStyle
import org.json.simple.JSONArray
import tornadofx.*
import org.json.simple.JSONObject
import org.json.simple.parser.JSONParser
import sun.tools.jstat.Alignment
import java.util.ArrayList
import java.util.LinkedHashMap


class FieldGenerator : App(MainView::class) {
    val controller: FieldGeneratorController by inject()
    var newFieldMap = LinkedHashMap<String, LinkedHashMap<String,ArrayList<String>>>()
    override fun start(stage: Stage) {
        if (parameters.unnamed.isEmpty()) {
            println("Please provide field map information")
            System.exit(-1) // ok to kill since it's a separate process with separate JVM so won't kill MATLAB JVM
        }
        else {
            val json = parameters.unnamed[0]
            controller.getEventValues(json)
            super.start(stage)
        }
    }

    override fun stop() {
        newFieldMap = controller.newValuesFieldMaps.valuesFieldMap

        val obj = JSONObject()
        for (field in newFieldMap.keys) { // for each new field value
            // there's associated field-value object LinkedHashMap
            val associatedObj = JSONObject()
            val map: LinkedHashMap<String, ArrayList<String>>? = newFieldMap[field]
            if (map != null) {
                for (associatedField in map.keys) {
                    val list = JSONArray()
                    val arrayList = map[associatedField] as ArrayList<String>
                    for (value in arrayList) {
                        list.add(value)
                    }

                    associatedObj.put(associatedField, list)
                }
            }
            obj.put(field, associatedObj)
        }
        println(obj.toJSONString())
    }

}

/** Controller **/
class FieldGeneratorController : Controller() {
    var newFieldName: String? = null
    val initialfieldMap = mutableMapOf<String, Any?>()

    val mainView: MainView by inject()

    val newValuesFieldMaps = NewValuesFieldMap()
    val tmpValueMap = LinkedHashMap<String, ArrayList<String>>()

    fun getValuesFromSelectedField(selectedField: String): ArrayList<String> {
        val values = initialfieldMap[selectedField]
        var returningList = ArrayList<String>()
        if (values is String)
            returningList.add(values)
        else
            returningList = values as ArrayList<String>
        return returningList
    }

    fun getEventValues(eventFieldJson: String) {
        val parser = JSONParser()
        val json = parser.parse(eventFieldJson)
        if (json is JSONObject) {
            newFieldName = json.get("newFieldName").toString()
            val eventFields = json.get("eventFields")
            if (eventFields is JSONObject) {
                val fieldNames = eventFields.keys
                for (field in fieldNames) {
                    initialfieldMap.put(field.toString(), eventFields[field])
                }
            }
        }
    }

//    fun newValueMapSelectFieldHandler() {
//        val selectedField = mainView.fieldCB.selectionModel.selectedItem
//
//        if (selectedField != null) {
//            // update valueListView
//            mainView.valueListView.items = FXCollections.observableArrayList(getValuesFromSelectedField(selectedField))
//
//            // highlight values of field if previously selected
//            if (tmpValueMap.containsKey(selectedField)) {
//                val selectedValues = tmpValueMap[selectedField]
//                if (selectedValues != null) {
//                    for (item in selectedValues) {
//                        mainView.valueListView.selectionModel.select(item)
//                    }
//                }
//            }
//        }
//    }

    fun fieldValueSelectedHandler() {
        if (!mainView.valueNameTF.text.isEmpty()) {
            val selectedItems = mainView.valueListView.selectionModel.selectedItems
            val listView = mainView.valueListView
            if (selectedItems != null && listView.items.size > 0) {
                val field = mainView.fieldCB.selectedItem.toString()

                if (selectedItems.size == 0 && tmpValueMap.containsKey(field)) {
                    // no value for this field, remove from map
                    tmpValueMap.remove(field)
                }
                else
                    tmpValueMap.put(field, ArrayList(selectedItems))

//                println(tmpValueMap)
            }
        }
    }
    fun addNewValue(newValueName: String, tmpValueMap: LinkedHashMap<String, ArrayList<String>>) {
//        val newValueName = mainView.valueNameTF.text

        // validation
        if (newValueName == null || newValueName.isEmpty()) {
            alert(Alert.AlertType.ERROR, "Empty value name", "Please enter new value name", ButtonType.OK)
            return
        }
        if (tmpValueMap.isEmpty()) {
            alert(Alert.AlertType.ERROR, "Empty field map", "Please select associated fields and field values", ButtonType.OK)
            return

        }
        // add to value field map
        newValuesFieldMaps.addValue(newValueName, tmpValueMap)
        tmpValueMap.clear()

//        // update UI
//        mainView.valueNameTF.clear()
//        mainView.fieldCB.value = null
//        mainView.valueListView.items = FXCollections.observableArrayList()
        mainView.mainTabPane.selectionModel.selectNext()
    }

    fun removeValue(valueName : String) {
        newValuesFieldMaps.removeValue(valueName)
    }
}

class NewValuesFieldMap {
    val valuesFieldMap = LinkedHashMap<String, LinkedHashMap<String, ArrayList<String>>>()
    val valuesList = FXCollections.observableArrayList<String>()
    fun addValue(valueName: String, fieldMap: LinkedHashMap<String, ArrayList<String>>) {
        // deep copy fieldMap
        val cloneMap = LinkedHashMap<String, ArrayList<String>>()
        fieldMap.forEach { field, values -> cloneMap.put(field, values.clone() as ArrayList<String>) } // deep copy

        // update
        valuesFieldMap.put(valueName, cloneMap)
        valuesList.setAll(valuesFieldMap.keys)
    }

    fun removeValue(valueName: String) {
        if (valuesFieldMap.containsKey(valueName)) {
            valuesFieldMap.remove(valueName)
        }
        if (valuesList.contains(valueName)) {
            valuesList.remove(valueName)
        }

    }

    fun getFieldMap(value: String) : LinkedHashMap<String, ArrayList<String>>?{
        return valuesFieldMap[value]
    }

    override fun toString() : String{
        return valuesFieldMap.toString()
    }
}

/** View **/
class MainView: View() {
    val controller: FieldGeneratorController by inject() // value of controller properties was updated in start() of App

    var valueNameTF : TextField by singleAssign()
    var fieldCB : ComboBox<String> by singleAssign()
    var valueListView : ListView<String> by singleAssign()
    var mainTabPane : TabPane by singleAssign()


    override val root = vbox {
        style {
            backgroundColor += c(168,194,255)
        }
        borderpane {
            center {
                label("Create new field \"${controller.newFieldName}\"") {
                    textFill = c(0,0,102)
                    font = Font.font("Cambria", 20.0)
                }
            }
        }
        mainTabPane = tabpane {
            style {
                backgroundColor += c(168,194,255)
                background
            }
            tabClosingPolicy = TabPane.TabClosingPolicy.UNAVAILABLE
            tab("Add new field value") {
                add(ChooseView::class)
            }
            tab("Current values") {
                style {
                    textFill = c(0, 0, 102)
                }
                var fields = FXCollections.observableArrayList<String>()
                var eventValues =  FXCollections.observableArrayList<String>()
                var selectedValue = ""
                gridpane {
                    padding = Insets(10.0,10.0,10.0,10.0)
                    row {
                        /* New event value panel */
                        label("New event values:") {
                            style {
                                textFill = c(0, 0, 102)
                            }
                        }
                        label("Associated event values") {
                            style {
                                textFill = c(0, 0, 102)
                            }
                        }
                    }
                    row {
                        label()
                        label("EEG.event field: ") {
                            style {
                                textFill = c(0, 0, 102)
                            }
                        }
                        combobox<String> {
                            items = fields
                            selectionModel.selectedItemProperty().onChange {
                                if (selectionModel.selectedItem != null) {
//                                    println("fieldMap: " + controller.newValuesFieldMaps.getFieldMap(selectedValue))
                                    if (!selectedValue.isEmpty()) {
                                        val fieldMap = controller.newValuesFieldMaps.getFieldMap(selectedValue)
                                        if (fieldMap != null) {
                                            eventValues.setAll(fieldMap[selectionModel.selectedItem.toString()])
                                        }
                                    }
                                }
                            }
                        }
                    }
                    row {
                        listview(controller.newValuesFieldMaps.valuesList) {
                            onMouseClicked = EventHandler {
                                if (selectionModel.selectedItem != null) { // when an item is selected
                                    selectedValue = selectionModel.selectedItem.toString()
                                    val fieldMap = controller.newValuesFieldMaps.getFieldMap(selectedValue)
                                    if (fieldMap != null) {
                                        fields.setAll(fieldMap.keys)
                                        eventValues.clear()
                                    }
                                }
                            }
                        }
                        listview(eventValues) {
                            gridpaneConstraints {
                                columnSpan = 2 // to match with two columns above
                            }
                            selectionModel.selectionMode = SelectionMode.SINGLE
                        }
                    }
                    row {
                        button("Remove") {
                            action {
                                controller.removeValue(selectedValue)
                            }
                        }
                        button("Done") {
                            gridpaneConstraints {
                                columnSpan = 2
                            }
                            action {
                                primaryStage.hide()
                            }
                        }
                    }
                }
            }
        }
    }
    init {
        title = "Create new field"
    }
}

class ChooseView: View() {
    override val root = vbox {
        style {
            padding = box(10.px)
            alignment = Pos.TOP_CENTER
            spacing = 20.px
        }
        label("How would you like to generate the new value?") {
            style {
                fontSize = 20.px
                fontWeight = FontWeight.EXTRA_BOLD
                textFill = c(0,0,102)
            }
        }
            button("By combining multiple values of a field into one\n(e.g. combining multiple event types into one condition)") {
                style {
                    textAlignment = TextAlignment.CENTER
                }
                action {
                    replaceWith<SingleCombineView>()
                }
            }
            button("By associating one value of a field with multiple values of another field\n(e.g. combining a condition code with other event types\nto generate specific condition-stimulus type code)") {
                style {
                    textAlignment = TextAlignment.CENTER
                }
                action {
                    replaceWith<DoubleCombineView>()
                }
            }
    }
}

class SingleCombineView: View() {
    val controller: FieldGeneratorController by inject() // value of controller properties was updated in start() of App

    var valueNameTF : TextField by singleAssign()
    var fieldCB : ComboBox<String> by singleAssign()
    var valueListView : ListView<String> by singleAssign()
    override val root = vbox {
        style {
            padding = box(10.px)
            spacing = 10.px
            textFill = c(0, 0, 102)
        }
        button("Switch method") {
            action {
                replaceWith<DoubleCombineView>()
            }
        }
        hbox {
            label("New value name: ") {
                 style {
                     textFill = c(0, 0, 102)
                 }
            }
            valueNameTF = textfield { }
        }
        vbox {
            label("Associated event values") {
                padding = Insets(10.0,0.0,10.0,0.0)
                style {
                    textFill = c(0, 0, 102)
                }
            }
            label("EEG.event field ") {
                style {
                    textFill = c(0, 0, 102)
                }
            }
            fieldCB = combobox<String> {
                items = FXCollections.observableArrayList(controller.initialfieldMap.keys)
                selectionModel.selectedItemProperty().onChange {
                    valueListView.items = FXCollections.observableArrayList(controller.getValuesFromSelectedField(selectionModel.selectedItem.toString()))
                }
            }
            valueListView = listview<String> {
                selectionModel.selectionMode = SelectionMode.MULTIPLE
            }
        }
        borderpane {
            right = button("Add") {
                action {
                    // get field-value map from selected
                    val tmpMap = LinkedHashMap<String, ArrayList<String>>()
                    tmpMap.put(fieldCB.selectedItem.toString(), valueListView.selectionModel.selectedItems.toCollection(ArrayList<String>()))

                    // add to the final map
                    controller.addNewValue(valueNameTF.text, tmpMap)
                }
            }
        }
    }
}

class DoubleCombineView: View() {
    val controller: FieldGeneratorController by inject() // value of controller properties was updated in start() of App

    var fieldOneCB : ComboBox<String> by singleAssign()
    var fieldTwoCB : ComboBox<String> by singleAssign()
    var valueOneListView : ListView<String> by singleAssign()
    var valueTwoListView : ListView<String> by singleAssign()
    override val root = vbox {
        style {
            padding = box(10.px)
            spacing = 10.px
        }
        button("Switch method") {
            action {
                replaceWith<SingleCombineView>()
            }
        }
        borderpane {
            left = vbox {
                label("Select main field") {
                    style {
                        textFill = c(0, 0, 102)
                    }
                }
                fieldOneCB = combobox<String> {
                    items = FXCollections.observableArrayList(controller.initialfieldMap.keys)
                    selectionModel.selectedItemProperty().onChange {
//                        controller.newValueMapSelectFieldHandler()
                        valueOneListView.items = FXCollections.observableArrayList(controller.getValuesFromSelectedField(selectionModel.selectedItem.toString()))
                    }
                }
                valueOneListView = listview<String> {
                    onMouseClicked = EventHandler{
//                        controller.fieldValueSelectedHandler()
                    }
                }

            }
            right = vbox {
                label("Select additional field") {
                    style {
                        textFill = c(0, 0, 102)
                    }
                }
                fieldTwoCB = combobox<String> {
                    items = FXCollections.observableArrayList(controller.initialfieldMap.keys)
                    selectionModel.selectedItemProperty().onChange {
                        //                        controller.newValueMapSelectFieldHandler()
                        valueTwoListView.items = FXCollections.observableArrayList(controller.getValuesFromSelectedField(selectionModel.selectedItem.toString()))
                    }
                }
                valueTwoListView = listview<String> {
                    selectionModel.selectionMode = SelectionMode.MULTIPLE
                    onMouseClicked = EventHandler{
//                        controller.fieldValueSelectedHandler()
                    }
                }

            }
        }
        borderpane {
            right = button("Add") {
                action {
                    // get field-value map from selected
                    val mainField = fieldOneCB.selectedItem.toString()
                    val mainFieldValue = valueOneListView.selectedItem.toString()
                    val associatedField = fieldTwoCB.selectedItem.toString()
                    val associatedFieldValues =
                        valueTwoListView.selectionModel.selectedItems.toCollection(ArrayList<String>())

                    val newName = NewNamePopUp(mainField,mainFieldValue,associatedField,associatedFieldValues)
                    newName.openModal(stageStyle = StageStyle.UTILITY)
                    for (value in associatedFieldValues) {
                        val tmpMap = LinkedHashMap<String, ArrayList<String>>()
                        val newValueName =  value + mainFieldValue
                        tmpMap.put(mainField, arrayListOf(mainFieldValue))
                        tmpMap.put(associatedField, arrayListOf(value))
                        controller.addNewValue(newValueName, tmpMap)
                    }
                }
            }
        }
    }
    class NewNamePopUp(val mainField:String, val mainFieldValue:String, val associatedField:String, val associatedFieldValues:ArrayList<String>) : Fragment() {
        val newNameList : ListView<String> by singleAssign()
        override val root = vbox {
            style {
                backgroundColor += c(168,194,255)
            }
            label("How would you like to generate new name(s) for the new value(s)?") {
                style {
                    textFill = c(0,0,102)
                }
            }
            combobox<String> {
                items = FXCollections.observableArrayList("Append value of " + mainField + " to values of " + associatedField,
                    "Append value of " + associatedField + " to values of " + mainField,
                    "Enter manually")
                selectionModel.selectedItemProperty().onChange {
                    print(selectedItem)
                    if (selectionModel.selectedIndex == 0) {
                        print("index 0")
                    }
                    else if (selectionModel.selectedIndex == 1) {
                        print("index 1")
                    }
                    else if (selectionModel.selectedIndex == 2) {
                        print("index 2")
                    }
                }
            }
            borderpane {
                left = listview(FXCollections.observableArrayList(mainFieldValue))
                center = listview(FXCollections.observableArrayList(associatedFieldValues))
                right = listview<String> {

                }
            }
        }
    }
}


