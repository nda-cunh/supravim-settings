public struct DataColor {
	double red;
	double green;
	double blue;

	public static DataColor rgb (int r, int g, int b) {
		DataColor color = {
			(double)r / 255.0, 
			(double)g / 255.0,
			(double)b / 255.0
		};
		return color;
	}
	public const DataColor black = {0.0, 0.0, 0.0};
	public const DataColor white = {1.0, 1.0, 1.0};
}
